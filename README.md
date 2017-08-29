Secure Remote Backups With Duplicity
====================================
Use duplicity and GPG to create encrypted incremental backups to the Amazon S3 service for important data.

This guide is written for Ubuntu, but the procedures should be more or less the same for any Linux flavour (and probably Mac).

## Amazon S3 Bucket
To set up Amazon S3 to host your backups, you will need and S3 Bucket and a dedicated IAM User with restricted capabilities.

Create the bucket and a new Amazon IAM user.

## IAM User Setup
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
## Bucket Setup
Go to the S3 section of the AWS console, and select the new bucket.

Select "Permissions" > ""Bucket Policy" to set up an appropriate policy. Don't waste your time mucking about with the "Access Control List" (like I did). It's deprecated and more or less impossible to add a user to the bucket access control list.

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
**NOTE**: You need to specificy subdirectories - see the "Resource" second entry.

## Encryption: GPG
Generate a dedicated GPG key with a strong passphrase:

~~~bash
gpg --gen-key
~~~

Enter your passphrase (twice) when prompted, and store your passphrase safely - for example in KeePassX.

This [tool](https://www.rempe.us/diceware/#eff) is a good way to generate strong passphrases - the number-generation at it's heart is based on a cryptographically secure pseudo random number generator. For maximum security, download the tool and run in an offline Tails session with no-one looking over your shoulder, listening-in, Van Eck phreaking your device etc. Or have some fun, go old school and [roll some dice](http://world.std.com/~reinhold/diceware.html)...use your throws to choose from a large wordlist - proper randomness.

A ten-word passphrase, pseudo-randomly selected from a keyspace of 7776 possible words will give you ~ 129 bits of entropy - which will take longer to brute force than the probable age of the universe. And this is just the passphrase - decryption is still going to require the private key, which remains in your possession on your computer.

The backup script also requires the eight byte short key ID for your GPG Key.

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
**`config.sh` is gitignored.** Make sure you keep it that way, so that you don't inadvertently share secrets.

## Directory Structure
@TODO

## Running backups
@TODO

## Restoring From Backup
@TODO
