create database gourmetclub default charset utf8;

use gourmetclub;

create table member (
    id          int not null primary key auto_increment,
    nickname    varchar(32) not null default '',
    mail        varchar(128) not null default '',
    password    char(27) not null default '',
    caller_id   int not null default 0,
    key (mail),
    key (caller_id)
) engine innodb;

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

create table scene (
    id      int not null primary key auto_increment,
    value   varchar(255) not null default '',
    created_by int not null default 0,
    created_at datetime
);

create table restrant (
    id      int not null primary key auto_increment,
    name    varchar(255) not null default '',
    tel     varchar(16) not null default '',
    address varchar(255) not null default '',
    created_by int not null default 0,
    created_at datetime,
    modified_at datetime
);

create table review (
    id          int not null primary key auto_increment,
    restrant_id int not null default 0,
    budget      varchar(32) not null default '',
    scene_id    int,
    comment     text,
    created_by  int not null default 0,
    created_at  datetime,
    modified_at datetime
);

-- vim: set ft=mysql
