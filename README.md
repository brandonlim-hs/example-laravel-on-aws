# Example - Laravel application on AWS

Example project that deploys a Laravel application on AWS via Elastic Beanstalk.

## Getting Started

### Local development

1. Copy `.env.example` to `.env`, then update environment variables in `.env`.

2. Start Docker containers

    `docker-compose -f docker-compose.yml -f .docker/docker-compose/docker-compose.local.yml up -d`

3. Compile PHP and JS

    1. SSH into app container

        `docker exec -it app bash`

    2. Compile PHP and JS

        ```
        composer install
        npm install && npm run dev
        ```

4. Migrate and seed data if required

    1. SSH into app container

        `docker exec -it app bash`

    2. Migrate and seed data

        ```
        php artisan migrate
        php artisan db:seed
        ```

5. Access Laravel application at http://localhost:80

### AWS Deployment

1. Create AWS RDS

2. Add environment variables to AWS System Manager Parameter Store. The parameter names should begin with `/Laravel/`

3. Create AWS Elastic Beanstalk application and environment

    `aws cloudformation create-stack --stack-name {stack-name} --template-body file://.cfn/template.yml --parameters file://.cfn/parameters.json --capabilities CAPABILITY_NAMED_IAM`

4. Create AWS CodePipeline to deploy code to AWS Elastic Beanstalk

## More

### Database migrations

Post deploy script is used to perform database migrations after every deployment to AWS Elastic Beanstalk. See: `.platform/hooks/postdeploy/01_database_migrations.sh`

### Docker

This example uses [multi-stage Dockerfile](https://docs.docker.com/develop/develop-images/multistage-build/) to allow the local environment to mimic the production environment as much as possible.

| Docker compose file                               | Description                                    |
| ------------------------------------------------- | ---------------------------------------------- |
| `.docker/docker-compose/docker-compose.local.yml` | Local development Docker compose file          |
| `.docker/docker-compose/docker-compose.eb.yml`    | Elastic Beanstalk specific Docker compose file |

### Environment Variables

This example uses AWS System Manager Parameter Store to manage environment variables.
Environment variables added to Elastic Beanstalk's option settings are merged with environment variables from Parameter Store.
The priority of environment variables are:

1. Environment variables added to Elastic Beanstalk's option settings
2. Environment variables from Parameter Store

A pre-build script is used to get environment variables from Parameter Store and saves them to .env file. See: `.platform/hooks/prebuild/02_environment_variables.sh`

### Logs

Docker volumes are used to allow logs from Laravel application and Nginx web server to be retrieved from Elastic Beanstalk instance. See: `.docker/docker-compose/docker-compose.eb.yml`
