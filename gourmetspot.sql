create table member (
    id          int not null primary key auto_increment,
    nickname    varchar(32) not null default '',
    mail        varchar(128) not null default '',
    password    char(27) not null default '',
    caller_id   int not null default 0,
    key (mail),
    key (caller_id)
) engine innodb;

create table role (
    id      int not null primary key auto_increment,
    role    varchar(32) not null default ''
);

create table member_role (
    member_id   int,
    role_id     int,
    primary key(member_id, role_id)
);

create table session (
    id              char(72) primary key,
    session_data    text,
    expires         int
) engine innodb;

create table invitation (
    id          int not null primary key auto_increment,
    caller_id   int not null default 0,
    mail        varchar(128) not null default '',
    nonce       char(27) not null default '',
    created_at  datetime,
    member_id   int,
    joined_at   datetime,
    key (caller_id),
    key (nonce)
);
    
create table reset_password (
    id          int not null primary key auto_increment,
    member_id     int not null default 0,
    nonce       char(27) not null default '',
    expires_at  datetime,
    key (nonce)
);

create table tag (
    id      int not null primary key auto_increment,
    value   varchar(255) not null unique default '',
    created_by int not null default 0,
    created_at datetime
);

create table restrant (
    id      int not null primary key auto_increment,
    name    varchar(255) not null default '',
    tel     varchar(16) not null default '',
    address varchar(255) not null default '',
    building varchar(255) not null default '',
    latitude decimal(10,6) not null default 0,
    longitude decimal(10,6) not null default 0,
    panorama text not null default '',
    how_to_get_there text,
    open_hours_memo text,
    created_by int not null default 0,
    created_at datetime,
    modified_at datetime
);

create table open_hours (
    id int not null primary key auto_increment,
    restrant_id int not null default 0,
    day_of_week set('Sun','Mon','Tue','Wed','Thu','Fri','Sat'),
    holiday     enum('true','false','masked') not null default 'false',
    pre_holiday enum('true','false','masked') not null default 'false',
    opens_at    time,
    closes_at   time
);

create table review (
    id          int not null primary key auto_increment,
    restrant_id int not null default 0,
    budget      int not null default 0,
    comment     text,
    created_by  int not null default 0,
    created_at  datetime,
    modified_at datetime
);

create table tag_review (
    tag_id  int not null default 0,
    review_id int not null default 0,
    restrant_id int not null default 0,
    primary key(tag_id, review_id)
);

-- vim: set ft=mysql
