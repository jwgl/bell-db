create type tm_hunt.level as enum (
    'UNIVERSITY',
    'CITY',
    'PROVINCE',
    'NATION'
);
alter type tm_hunt.level owner to tm;

create type tm_hunt.status as enum (
    'CREATED',
    'INHAND',
    'FINISHED',
    'CUTOUT'
);
alter type tm_hunt.status owner to tm;

create type tm_hunt.review_type as enum (
    'APPLICATION',
    'CHECK',
    'OTHER'
);
alter type tm_hunt.review_type owner to tm;

create type tm_hunt.conclusion as enum (
    'OK',
    'VETO',
    'DELAY'
);
alter type tm_hunt.conclusion owner to tm;