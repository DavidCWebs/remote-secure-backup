Secure Remote Backups With Duplicity
====================================
## Use Duplicity and GnuPG to create encrypted incremental backups to the Amazon S3 service.

Duplicity is a network backup utility that has the ability to incrementally save snapshots of data in remote filesystems. Duplicity is a Python command-line tool. It uses a range of protocols to transfer data - possibly the most interesting being rsync, scp and Amazon S3. This project is a simple wrapper for Duplicity saving to Amazon S3, but it would be easy to modify the scripts to access remote filesystems using scp or rsync.

This guide is written for Ubuntu 16.04 running Duplicity 0.7.06, but the procedures should be more or less the same for any Linux flavour (and probably Mac).

Because Duplicity does not support hard links, the backup script includes an additional step that uses rsync to create a staging directory that includes what symlinks are pointing to. This is important for my particular use case, as my target directory serves as a single point of truth for crucial files and directories. Note that what you restore will include the files that the original symlinks pointed to.

**Note:** Later versions of Duplicity (0.8) have the `--copy-links` option, which makes the rsync step unecessary. See here: https://askubuntu.com/a/941710/463571 and here: https://code.launchpad.net/~horgh/duplicity/copy-symlink-targets-721599.

## Amazon S3
To set up Amazon S3 to host your backups, you will need to set up an S3 Bucket and a dedicated IAM User with appropriate (limited) capabilities.

### IAM User Setup
When you create the new user, record the IAM credentials - especially the secret which is only shown once when the identity is generated (crack open your password manager for this).

In the IAM console, create a permissions policy for the new user, providing full access to the new bucket. The policy will look something like this:

~~~js
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt2425037385313",
            "Effect": "Allow",
            "Action": [
                "s3:*"
            ],
            "Resource": [
                "arn:aws:s3:::your-unique-bucket-name"
            ]
        }
    ]
}
~~~
### Bucket Setup
Go to the S3 section of the AWS console, and select the new bucket. Select "Permissions" > ""Bucket Policy" to set up an appropriate policy. Don't waste your time mucking about with the "Access Control List" (like I did). It's deprecated and more or less impossible to add a user to the bucket access control list.

Create a bucket policy - use the policy generator if you like. The policy should look something like this:

~~~js
{
    "Version": "2012-10-17",
    "Id": "Policy1503955199969",
    "Statement": [
        {
            "Sid": "Stmt150378999997",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::496574764374:user/BackupUser",
                    "arn:aws:iam::494738882939:user/MainUser"
                ]
            },
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::your-unique-bucket-name",
                "arn:aws:s3:::your-unique-bucket-name/*"
            ]
        }
    ]
}
~~~
**NOTE**: You need to specify subdirectories - see the "Resource" second entry.

## Encryption: GnuPG
Generate a dedicated GnuPG key with a strong passphrase:

~~~bash
gpg --gen-key
~~~

Enter your passphrase (twice) when prompted, and store your passphrase safely - for example in KeePassX.

This [tool](https://www.rempe.us/diceware/#eff) is a good way to generate strong passphrases - the number-generation at it's heart is based on a cryptographically secure pseudo random number generator. For maximum security, download the tool and run in an offline Tails session with no-one looking over your shoulder, listening-in, Van Eck phreaking your device etc. Or have some fun, go old school and [roll some dice](http://world.std.com/~reinhold/diceware.html)...use your throws to choose from a large wordlist - proper randomness.

A ten-word passphrase, pseudo-randomly selected from a keyspace of 7776 possible words will give you ~ 129 bits of entropy - which will take longer to brute force than the probable age of the universe. And this is just the passphrase - decryption of your data is still going to require the private key, which remains in your possession on your computer.

The backup script also requires the eight byte short key ID for your GnuPG Key.

If you list keys with `gpg --list-keys`, you can get the required ID - the number quoted in the `pub` line after the key size:

~~~bash
pub   4096R/6D4459F3 2017-08-28 [expires: 2017-09-28]
uid                  key-name (Key comment)
~~~

## Set Config
Copy `sample-config.sh` to `config.sh` and enter the relevant values in `config.sh`.

~~~bash
cp sample-config.sh config.sh
~~~
**`config.sh` in this repo is gitignored.** Make sure you keep it that way, so that you don't inadvertently share secrets. You could clone this repo and get rid of git altogether.

## Directory Structure & Incremental Backups
The first time the backup script runs, Duplicity will create a full backup. From this point onwards, backups are incremental, up to the time limit set by `DAYS_TO_FULL_BACKUP`.

Incremental backups only add differences from the last full or incremental backup. To figure out what needs to be backed up, Duplicity creates data files that are related to the backed-up data. The backup archives have the `difftar` extension. Duplicity files created by a full backup are prepended `duplicity-full`, whereas files created during incremental backup are prepended `duplicity-inc`. To determine changes, Duplicity needs information about previous backups. It does this by storing a collection of file signatures in a signature tarfile with the extension `sigtar`.

**Signature sets are stored locally, unencrypted, in the Duplicity archive directory.** They are also stored remotely in encrypted format.

Without an up-to-date signature, a Duplicity backup cannot append an incremental backup to an existing archive.

>To save bandwidth, duplicity generates full signature sets and incremental signature sets. A full signature set is generated for each full backup, and an incremental one for each incremental backup. These start with duplicity-full-signatures and duplicity-new-signatures respectively. These signatures will be stored both locally and remotely. The remote signatures will be encrypted if encryption is enabled. The local signatures will not be encrypted and stored in the archive dir (see --archive-dir ).
> http://www.nongnu.org/duplicity/duplicity.1.html#toc29

## Running backups
Create a symlink to `duplicity-encrypted.sh` in `/usr/local/bin` or another suitable directory in your `$PATH`:

~~~bash
sudo ln -s /path/to/repo/duplicity-encrypted.sh /usr/local/bin/backup-my-secrets
~~~

Entering `backup-my-secrets` will now trigger the backup. Adding this to a cronjob is probably a good idea.

## Restoring From Backup
Create a symlink to `restore-encrypted.sh` in `/usr/local/bin` or another suitable directory in your `$PATH`:

~~~bash
sudo ln -s /path/to/repo/restore-encrypted.sh /usr/local/bin/restore-my-secrets
~~~

Enter `restore-my-secrets` to trigger the restore. The script will prompt you to specify a parent directory for the restore, and the restored decrypted files will be added to a directory (named by the current timestamp) in this parent. Duplicity doesn't overwrite (by default) and restoring files is not an everyday occurrence in this particular use-case - so this is a reasonable approach.

You will be prompted for your GnuPG passphrase when restoring - as your secret key is needed to perform the decryption.

## To Do
Add a config generator script.

## Resources & References
[Duplicity Guide](http://duplicity.nongnu.org/duplicity.1.html)
