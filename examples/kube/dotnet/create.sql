drop table "NameDirectory";
create table "NameDirectory" ("ID" serial not null primary key unique, "FirstName" text, "LastName" text, "CreatedTimestamp" text);
drop table "__EFMigrationsHistory";
create table "__EFMigrationsHistory" ("MigrationId" text not null primary key, "ProductVersion" text not null);
