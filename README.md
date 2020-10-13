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

2. Create AWS Elastic Beanstalk application and environment

3. Update AWS Elastic Beanstalk configurations

4. Create AWS CodePipeline to deploy code to AWS Elastic Beanstalk

## More

### Database migrations

Post deploy script is used to perform database migrations after every deployment to AWS Elastic Beanstalk. See: `.platform/hooks/postdeploy/01_database_migrations.sh`

### Docker

This example uses [multi-stage Dockerfile](https://docs.docker.com/develop/develop-images/multistage-build/) to allow the local environment to mimic the production environment as much as possible.
