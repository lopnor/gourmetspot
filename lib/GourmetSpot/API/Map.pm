package GourmetSpot::API::Map;
use Moose;
use utf8;
use Geo::Coordinates::Converter;
use WebService::Simple;
use Geo::Google::StaticMaps::Navigation;

has apikey => (
    isa => 'Str',
    is  => 'ro',
);

sub reverse_geocode {
    my ($self, $coordinates) = @_;
    my $api = $self->_get_geoapi;
    my $res = $api->get(
        {ll => join(',', $coordinates->lat, $coordinates->lng)}
    );
    if ($res->is_success) {
        my $geo = eval {$res->parse_response->documentElement};
        if ($geo && $geo->getElementsByTagName('code')->shift->textContent eq '200') {
            my ($nearest) = $self->_get_placemarks($geo);
            return $self->_address($nearest);
        }
    }
}

sub geocode {
    my ($self, $address) = @_;
    my $api = $self->_get_geoapi;
    my $res = $api->get({q => $address});
    if ($res->is_success) {
        my $geo = eval {$res->parse_response->documentElement};
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
                lng => $self->_find_param($query, qr{lon|LON}),
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

sub _get_geoapi {
    my ($self) = @_;
    my $api = WebService::Simple->new(
        base_url => 'http://maps.google.com/maps/geo',
        response_parser => 'XML::LibXML',
        param => {
            output => 'xml',
            gl => 'jp',
        }
    );
}

sub _address {
    my ($self, $elem) = @_;
    my $area = $elem->getElementsByTagName('AdministrativeArea')->shift;
    if ($area) {
        my @address;
        for (qw(AdministrativeAreaName SubAdministrativeAreaName LocalityName DependentLocalityName)) {
            my $item = $area->getElementsByTagName($_)->shift;
            push @address, $item->textContent if $item;
        }
        return join(' ', @address);
    } else {
        my $address = $elem->getElementsByTagName('address')->shift->textContent;
        if ($address =~ s/ station Japan//) {
            return $address;
        }
    }
}

sub _get_placemarks {
    my ($self, $elem) = @_;
    return sort {$self->_get_accuracy($b) <=> $self->_get_accuracy($a) } $elem->getElementsByTagName('Placemark')
}

sub _get_accuracy {
    my ($self, $elem) = @_;
    return $elem->getElementsByTagName('AddressDetails')->shift->getAttribute('Accuracy');
}

sub _find_prefecture {
    my ($self, $arg) = @_;
    warn $arg;
    return $arg;
}

1;
