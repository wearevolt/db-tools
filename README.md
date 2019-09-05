# Db backup and restore

##Configuration

Following env variables are required:
```
DB_BACKUP_AWS_ACCESS_KEY_ID=<Some key>
DB_BACKUP_AWS_SECRET_ACCESS_KEY=<Some secret key>
DB_BACKUP_AWS_DEFAULT_REGION=us-east-1
DB_BACKUP_TARGET_BUCKET=<bucket-name>
DB_BACKUP_ROOT=dev/cc_edit_dev
DB_BACKUP_BASE_NAME=cc_edit_dev
```

## Taking backup

Create backup and upload it to configured s3 bucket
```
bin/db_backup_to_s3 [--name-prefix="some_prefix_"] [--name-suffix="_some_suffix"]
```

Remote backup file key generated using mask,
$Y $m $d $H $M $S are correspondingly year, month, day, hour, minute, second.

```
$DB_BACKUP_ROOT/$Y/$Y-$m/$Y-$m-$d/${NAME_PREFIX}${DB_BACKUP_BASE_NAME}_$Y_$m_$d__$H_$M_$S${NAME_SUFFIX}.dump
```

## Listing backups

List backups with given prefix:
```
bin/db_ls_backups \
  [--prefix=<dev/cc_edit_dev>] \
  [--left-bound="00:00 today UTC"] \
  [--right-bound="00:00 tomorrow UTC"] \
  [--day="00:00 today UTC"] \
  [--next-page=<next-page-token>]
```

Backups are filtered by upload timestamp, that can be defined by either --left-bound
and --right-bound, or --day parameter. By default 2 days interval from yesterday midnight
to tomorrow midnight used. If day parameter used, then left bound set to day value,
and right parameter is set to left bound + 1 day.


## Restoring db backup

Download latest db backup and restore it to a newly created database:

```
bin/db_backup_restore
```

Download latest db backup and restore it to an existing database:

```
bin/db_backup_restore --create-database=false
```

Download given db backup and restore it to newly created database:
```
bin/db_backup_restore --remote-file=foo/bar/some-remote-file-path.dump
```

Download db backup from sugned url and restore it to an existing database:
```
bin/db_backup_restore \
  --signed-url=http://example.com/foo/bar/some-remote-file-path.dump \
  --create-database=false
```