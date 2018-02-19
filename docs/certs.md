# Generating Certs

There are 2 options for generating certs.  Let's assume below that we are doing this for the 
"sre.dev.oracledx.com" domain name and "dev-region/new-env" environment:


## Issue a Letsenrypt Certificate
1. Install certbot using yum ```yum install certbot```
1. Create a cert, for example: ```certbot certonly --manual --agree-tos --register -d sre.dev.oracledx.com --preferred-challenges dns-01```
1. After you create a cert the actual cert will be stored in ```/etc/letsencrypt/live/sre.dev.oracledx.com```
1. Copy this directory to the cert location for your environment.  

```
cp -r /etc/letsencrypt/live/sre.dev.oracledx.com envs/dev-region/new-env/certs
```

## Create a Self Signed Certificate
1. Create the directory to store the certs: 

```
mkdir envs/dev-region/new-env/certs
```

1. Generate the certs:

```
export NEWENV=envs/dev-region/new-env/certs
openssl req -subj "/C=US/ST=Oregon/L=Portland/O=OracleDX/OU=Org/CN=sre.dev.oracledx.com" \ 
-new -x509 -sha256 -newkey rsa:2048 -nodes \
-keyout $NEWENV/privkey.pem -days 365 -out $NEWENV/cert.pem
```

1. Since we don't have a real certification authority we need to provide an empty certchain:

```
touch $NEWENV/chain.pem
touch $NEWENV/fullchain.pem
```