# Edge-Secured Microservices Architecture

A zero-trust, containerized microservices environment featuring a custom OpenResty API Gateway. This architecture handles edge-level JWT authentication and Redis-backed rate limiting before routing traffic to isolated internal services.

## Architecture Overview

This project implements a strict network isolation strategy. The API Gateway acts as the sole public entry point, protecting backend services from direct external access.

* **API Gateway (OpenResty/Nginx):** Custom Docker image running Lua scripts for request validation.
* **Rate Limiter (Redis):** Implements a highly efficient Token Bucket algorithm using connection pooling.
* **Auth Service (Spring Boot):** Issues secure JWTs, connected to a dedicated PostgreSQL database.
* **Backend Service:** The protected core application layer.

## Key Features

* **Edge Authentication:** JWTs are verified cryptographically at the proxy layer before reaching the backend.
* **Smart Rate Limiting:** Lua-driven Token Bucket algorithm prevents API abuse. "Fails open" gracefully if Redis goes offline to maintain availability.
* **Header Injection:** The gateway extracts the valid `userId` from the JWT and injects it as an `X-User-Id` header for downstream services.
* **Network Isolation:** Internal services (Auth, Backend, DB, Cache) run on isolated Docker bridge networks and do not expose ports to the host machine.

## Project Folder Structure

```text
/
├── docker-compose.yml
├── .env                  # ( Must be created manually or existing should be changed before use )
├── gateway/
│   ├── Dockerfile
│   ├── conf/
│   │   └── nginx.conf
│   └── scripts/
│       └── lua/
│           ├── main.lua
│           ├── rate_limiter.lua
│           └── verification.lua
```
## Quick Start Guide

**1. Prerequisites**

* **[Docker](https://docs.docker.com/engine/install/)** and Docker Compose installed.
  
**2. Environment Variables**
   Create a .env file in the root directory and cnange define the following secrets or rename .env.example to .env and change the following:

   ```bash
    JWT_SECRET=your_super_secret_cryptographic_key
    POSTGRES_USER=admin
    POSTGRES_PASSWORD=secure_database_password
   ```
   
**3. Build and Launch**

Build the custom gateway image and spin up the isolated network:

   ```bash
    docker-compose up -d --build
   ```
Wait approximately 20-30 seconds on the first boot for the PostgreSQL database to initialize and the Spring Boot Auth service to become healthy.

**4. Verification & Teardown**

* To check the status of your containers:
   ```bash
    docker-compose ps
  ```
* To view gateway logs
  ```bash
    docker logs api_gateway
   ```
* To tear down the environment and remove the networks:
   ```bash
    docker-compose down 
   ```

**5. API Usage & Testing**

The Gateway is exposed on ``` http://localhost:3300. ```
* Step 1: Obtain a Token

Since the Auth service is bypassed for login routes, obtain your JWT directly from the Auth container (mapped to port 8500 locally for testing):

```bash

curl -X POST http://localhost:8500/login \
     -H "Content-Type: application/json" \
     -d '{"username": "testuser", "password": "password"}'
```

* Step 2: Access the Protected Backend

Pass the token to the API Gateway. The Gateway will validate the token, check the rate limit, and forward the request to the Backend service.

```bash
  curl -X GET http://localhost:3300/api/data \
     -H "Authorization: Bearer <YOUR_JWT_TOKEN>"

```

* Step 3: Trigger the Rate Limiter

Spam the protected endpoint more than 10 times within a minute. The Gateway will intercept the requests and return:
JSON
```
{
  "status": "error", 
  "message": "TOO MANY REQUESTS. Please try again later."
}
```
