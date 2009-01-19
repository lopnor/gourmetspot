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
    key (caller_id),
    key (nonce)
);
    

-- vim: set ft=mysql
