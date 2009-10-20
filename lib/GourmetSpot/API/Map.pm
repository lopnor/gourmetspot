package GourmetSpot::API::Map;
use Moose;
use utf8;
use charnames ':full';
use YAML::Syck;
use Geo::Coordinates::Converter;
use WebService::Simple;
use Geo::Google::StaticMaps::Navigation;
use Geography::JapanesePrefectures::Unicode;

has apikey => (
    isa => 'Str',
    is  => 'ro',
);

has municipal_data_file => (
    isa => 'Str',
    is => 'ro',
);

has municipal_data => (
    isa => 'HashRef',
    is => 'ro',
    lazy => 1,
    default => sub {
        my ($self) = @_;
        local $YAML::Syck::ImplicitUnicode = 1;
        return YAML::Syck::LoadFile($self->municipal_data_file);
    },
);

sub reverse_geocode {
    my ($self, $coordinates) = @_;
    my $geo = $self->_get_geo(
        {ll => join(',', $coordinates->lat, $coordinates->lng)}
    );
    if ($geo && $geo->getElementsByTagName('code')->shift->textContent eq '200') {
        my ($nearest) = $self->_get_placemarks($geo);
        return $self->_address($nearest);
    }
}

sub geocode {
    my ($self, $address) = @_;
    my $geo = $self->_get_geo({q => $address});
    if ($geo && $geo->getElementsByTagName('code')->shift->textContent eq '200') {
        my @points;
        for my $p ($self->_get_placemarks($geo)) {
            my @coordinates = split(',', $p->getElementsByTagName('coordinates')->shift->textContent);
            my $point = Geo::Coordinates::Converter->new(
                lat => $coordinates[1],
                lng => $coordinates[0],
                datum => 'wgs84',
            );
            $point->convert(wgs84 => 'degree') if $point;
            $point->{address} = $self->_address($p);
            push @points, $point;
        }
        return @points;
    }
}

sub gps_to_coordinates {
    my ($self, $query) = @_;
    my $point;
    if ($query->param('pos')) {
        # supports only NE world...
        if ($query->param('pos') =~ m{N([\d\.]+)E([\d\.]+)}) {
            $point = Geo::Coordinates::Converter->new(
                lat => $1,
                lng => $2,
                datum => $query->param('geo'),
            );
        }
    } else {
        $point = eval {
            Geo::Coordinates::Converter->new(
                lat => $self->_find_param($query, qr{lat|LAT}),
                lng => $self->_find_param($query, qr{lon|LON|lng}),
                datum => $self->_find_param($query, qr{datum|GEO}),
            )
        };
    }
    $point->convert(wgs84 => 'degree') if $point;
    return $point;
}

sub distance_for_mysql {
    my ($self, $args) = @_;
    my $point = $args->{point} or return;
    my $latitude_column = $args->{latitude_column} || 'latitude';
    my $longitude_column = $args->{longitude_column} || 'longitude';
    
    return sprintf("((acos(sin((%s*pi()/180)) * sin((%s * pi()/180)) + cos((%s*pi()/180)) * cos((%s * pi()/180)) * cos(((%s - %s )*pi()/180)))) *180*60*1853/pi())",
        $point->lat,
        $latitude_column,
        $point->lat,
        $latitude_column,
        $point->lng,
        $longitude_column,
    );
}

sub static_map {
    my ($self, $args) = @_;
    my $center = Geo::Coordinates::Converter->new(
        lat => $args->{lat},
        lng => $args->{lng},
    ) || $args->{marker};

    my $map = Geo::Google::StaticMaps::Navigation->new(
        zoom_ratio => 2,
        key => $self->apikey,
        center => $center,
        width => $args->{width} || 100,
        height => $args->{height} || $args->{width} || 100,
        span => $args->{span} || 0.002,
        markers => $args->{markers} || [],
    );
}

sub _find_param {
    my ($self, $query, $regex) = @_;
    map {$query->param($_) } grep {$_ =~ $regex} $query->param;
}

sub _get_geo {
    my ($self, $args) = @_;
    my $api = WebService::Simple->new(
        base_url => 'http://maps.google.com/maps/geo',
        response_parser => 'XML::LibXML',
        param => {
            output => 'xml',
            gl => 'jp',
            key => $self->apikey,
        }
    );
    my $res = $api->get($args);
    if ($res->is_success) {
        return eval {$res->parse_response->documentElement};
    }
}

sub _address {
    my ($self, $elem) = @_;
    my $area = $elem->getElementsByTagName('AdministrativeArea')->shift;
    if ($area) {
        my @address;
        for (qw(AdministrativeAreaName SubAdministrativeAreaName LocalityName DependentLocalityName)) {
            my $item = $area->getElementsByTagName($_)->shift or next;
            my $address = $self->_normalize_address($item->textContent);
            push @address, $address;
        }
        return join(' ', @address);
    } else {
        my $address = $elem->getElementsByTagName('address')->shift->textContent;
        return $self->_normalize_address($address);
    }
}

sub _normalize_address {
    my ($self, $arg) = @_;
    $arg =~ s/(?: station Japan| Prefecture)$//;
    my ($japanese) = map {$_->{name}} 
                    grep {$_->{roman} eq $arg} 
                    @{Geography::JapanesePrefectures::Unicode->prefectures_infos};
    return $japanese if $japanese;
    my $m = $self->municipal_data->{$arg};
    return $m || $arg;
}

sub _get_placemarks {
    my ($self, $elem) = @_;
    return sort {$self->_get_accuracy($b) <=> $self->_get_accuracy($a) } $elem->getElementsByTagName('Placemark')
}

sub _get_accuracy {
    my ($self, $elem) = @_;
    return $elem->getElementsByTagName('AddressDetails')->shift->getAttribute('Accuracy');
}

1;
