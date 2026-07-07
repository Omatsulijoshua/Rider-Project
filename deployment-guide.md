# Rider Logistics Project - Deployment Guide

This guide provides instructions for deploying the **Rider Backend** (NestJS + Prisma + PostgreSQL) and the **Rider Admin Web** (Next.js) to production.

---

## 🛠️ Option A: Self-Hosted VPS Deployment (Docker Compose) - *Recommended*

This is the most cost-effective and flexible option if you have a Virtual Private Server (VPS) from providers like DigitalOcean, AWS (EC2), Linode, or Hetzner.

### 1. Prerequisites on VPS
Ensure your VPS has Docker and Docker Compose installed:
```bash
# Verify Docker installation
docker --version
docker compose version
```

### 2. DNS Setup
Point your domain or subdomains to your VPS IP address:
- `riderhq.africa` -> Points to VPS IP (for Admin Web)
- `api.riderhq.africa` -> Points to VPS IP (for NestJS Backend)

### 3. Clone and Setup Project
Clone your repository onto the VPS, and navigate to the project root:
```bash
cd /var/www/rider-logistics
```

Duplicate the env template and customize the values:
```bash
cp .env.example .env
nano .env
```
Ensure you update the database passwords and set a strong `JWT_SECRET`.

### 4. Run the Docker Stack
Launch the containers in detached (background) mode:
```bash
docker compose -f docker-compose.prod.yml up --build -d
```

This command will:
1. Spin up the **PostgreSQL** database and perform a health check.
2. Build and run the **NestJS Backend**, automatically applying Prisma migrations.
3. Build and run the **Next.js Admin panel** in standalone production mode.
4. Start **Nginx** as a reverse proxy mapping port 80 to routing rules.

Check status:
```bash
docker compose -f docker-compose.prod.yml ps
```

### 5. Setup SSL (HTTPS) with Let's Encrypt
To secure your site with HTTPS, install Certbot on your VPS:
```bash
sudo apt update
sudo apt install certbot -y
```

Obtain the SSL certificates:
```bash
sudo certbot certonly --standalone -d riderhq.africa -d api.riderhq.africa
```

Once certificates are obtained, update the `docker-compose.prod.yml` and `nginx.conf` to mount and use SSL certificates.

#### SSL Nginx Server Configuration Block Example:
Update `/etc/nginx/nginx.conf` (or mount into Nginx container) with:
```nginx
server {
    listen 80;
    server_name riderhq.africa api.riderhq.africa;
    return 301 https://$host$request_uri; # Redirect HTTP to HTTPS
}

server {
    listen 443 ssl;
    server_name riderhq.africa;

    ssl_certificate /etc/nginx/certs/live/riderhq.africa/fullchain.pem;
    ssl_certificate_key /etc/nginx/certs/live/riderhq.africa/privkey.pem;

    # Admin Panel
    location / {
        proxy_pass http://admin_server;
        ...
    }
}

server {
    listen 443 ssl;
    server_name api.riderhq.africa;

    ssl_certificate /etc/nginx/certs/live/riderhq.africa/fullchain.pem;
    ssl_certificate_key /etc/nginx/certs/live/riderhq.africa/privkey.pem;

    # Backend API
    location /api {
        proxy_pass http://backend_server;
        ...
    }

    # WebSockets (Socket.io)
    location /socket.io/ {
        proxy_pass http://backend_server;
        ...
    }
}
```

---

## ☁️ Option B: Cloud Platforms (PaaS) - *Easiest Setup*

If you don't want to manage a VPS, you can use serverless and managed hosting platforms.

### 1. Database (PostgreSQL)
Deploy a managed PostgreSQL database using:
- **Supabase** (Free Tier available)
- **Neon.tech** (Free Tier available)
- **Render PostgreSQL** (Paid/Free)
- **Railway PostgreSQL** (Paid)

Copy the database connection string (e.g., `postgresql://...`).

### 2. Deploy Backend on Render / Railway
#### On Render:
1. Create a new **Web Service** on Render and connect your GitHub repository.
2. Configure settings:
   - **Name**: `rider-backend`
   - **Root Directory**: `rider-backend`
   - **Environment/Runtime**: `Node`
   - **Build Command**: `npm install && npx prisma generate && npm run build`
   - **Start Command**: `npx prisma migrate deploy && node dist/main.js`
3. Add the following **Environment Variables**:
   - `DATABASE_URL`: *Your PostgreSQL connection string*
   - `PORT`: `3000`
   - `JWT_SECRET`: *Generate a secure secret*
   - `JWT_EXPIRES_IN`: `15m`
   - `NODE_ENV`: `production`
   - `PAYSTACK_SECRET`: *Your key if applicable*
4. Deploy the service. Render will expose a URL (e.g., `https://rider-backend.onrender.com`).

#### On Railway:
1. Create a new project and select **Deploy from GitHub repo**.
2. Set the Root Directory to `rider-backend`.
3. In variables, add all environment variables.
4. Railway will automatically detect NestJS and run it.

### 3. Deploy Admin Frontend on Vercel
Vercel is the native platform for Next.js and hosts it for free with high performance.

1. Go to [Vercel](https://vercel.com) and create a project.
2. Import your GitHub repository.
3. Configure settings:
   - **Root Directory**: `rider-admin-web`
   - **Framework Preset**: `Next.js`
   - **Build Command**: `next build`
   - **Output Directory**: `.next`
4. Add the following **Environment Variables**:
   - `NEXT_PUBLIC_API_URL`: `https://rider-backend.onrender.com/api` (Replace with your backend service URL)
5. Click **Deploy**. Vercel will build and deploy the Next.js app and assign a free subdomain (e.g., `https://rider-admin.vercel.app`). You can link your custom domain (e.g., `admin.riderhq.africa`) in the project settings.

---

## 🔐 Production Environment Variables Checklist

Ensure these variables are secure and configured before going live:

| Variable | Scope | Description | Recommendation |
|---|---|---|---|
| `DATABASE_URL` | Backend | Database Connection | Use pooled connection string |
| `JWT_SECRET` | Backend | Auth Signature | Use a 32+ character random string |
| `PAYSTACK_SECRET` | Backend | Payments | Use live API key in production |
| `NEXT_PUBLIC_API_URL` | Admin Web | API Endpoint | Point to the backend URL (`/api` or full domain) |
