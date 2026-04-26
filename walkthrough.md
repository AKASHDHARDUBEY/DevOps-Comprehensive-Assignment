# 🚀 DevOps Assignment — Complete Step-by-Step Walkthrough

> **You do everything yourself. This is your guide.**

---

## PART 1: Create EC2 Instance (AWS Console)

### Step 1.1 — Login to AWS
1. Open browser → go to **https://aws.amazon.com**
2. Click **Sign In to Console**
3. Enter your AWS credentials

### Step 1.2 — Navigate to EC2
1. In the search bar at top, type **EC2**
2. Click **EC2** from the results
3. Click the orange **Launch Instance** button

### Step 1.3 — Configure the Instance

Fill these settings one by one:

| Setting | What to Enter |
|---------|--------------|
| **Name** | `devops-assignment` |
| **AMI** | Select **Ubuntu Server 24.04 LTS** (free tier eligible) |
| **Instance type** | `t2.micro` (free tier) |
| **Key pair** | Click **Create new key pair** → Name it `devops-key` → Type: RSA → Format: `.pem` → Click **Create** (it downloads automatically) |

### Step 1.4 — Configure Security Group (Network Settings)

1. Click **Edit** on Network settings
2. Keep VPC as default
3. Under **Firewall (security groups)** → select **Create security group**
4. Add these **3 rules**:

| Type | Port | Source |
|------|------|--------|
| **SSH** | 22 | `0.0.0.0/0` (already there by default) |
| **HTTP** | 80 | `0.0.0.0/0` (click **Add security group rule** → select HTTP) |
| **HTTPS** | 443 | `0.0.0.0/0` (click **Add security group rule** → select HTTPS) |

### Step 1.5 — Configure Storage
- Keep default **8 GB gp3** (enough for this assignment)

### Step 1.6 — Launch
1. Click **Launch Instance**
2. Wait for it to say "Successfully launched"
3. Click on the **Instance ID** link to go to your instance

### Step 1.7 — Get Your Public IP
1. On the instance page, wait until **Instance State** shows **Running**
2. Copy the **Public IPv4 address** (something like `54.xx.xx.xx`)
3. Save this somewhere — you'll need it

---

## PART 2: Connect to EC2 via SSH

### Step 2.1 — Open your Terminal (on your Mac)

```bash
# First, go to where your key was downloaded
cd ~/Downloads

# Make the key file read-only (required by SSH)
chmod 400 devops-key.pem

# Connect to EC2 (replace the IP with your actual EC2 public IP)
ssh -i devops-key.pem ubuntu@YOUR_EC2_PUBLIC_IP
```

> When it asks "Are you sure you want to continue connecting?" → type **yes** and press Enter

You should now see something like:
```
ubuntu@ip-172-xx-xx-xx:~$
```

**You're now inside your EC2 machine! Everything from now on is typed here.**

---

## PART 3: Update System Packages (Check 03 — 2 marks)

### Step 3.1 — Update & Upgrade

```bash
sudo apt update
sudo apt upgrade -y
```

> This might take 2-3 minutes. Wait for it to finish.

**Why?** The grader checks that ALL system packages are up to date (0 pending upgrades).

---

## PART 4: Install Docker (Checks 01 & 02 — 4 marks)

### Step 4.1 — Install prerequisites

```bash
sudo apt install -y ca-certificates curl gnupg
```

### Step 4.2 — Add Docker's GPG key

```bash
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
```

### Step 4.3 — Add Docker repository

```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

### Step 4.4 — Install Docker Engine

```bash
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### Step 4.5 — Allow your user to run Docker without sudo

```bash
sudo usermod -aG docker $USER
newgrp docker
```

### Step 4.6 — Verify Docker is working

```bash
docker --version
```
> Should print something like: `Docker version 27.x.x`

```bash
docker info
```
> Should print lots of info without any errors

✅ **Check 01 passed** — Docker installed  
✅ **Check 02 passed** — Docker daemon active

---

## PART 5: Clone the Repository

### Step 5.1 — Clone

```bash
cd ~
git clone https://github.com/nst-sdc/DevOps-Comprehensive-Assignment.git
cd DevOps-Comprehensive-Assignment
```

### Step 5.2 — Verify files are there

```bash
ls -la
```

You should see: `backend/`, `frontend/`, `README.md`, `.dockerignore`, `.gitignore`

---

## PART 6: Fix the Code (2 Changes)

### Step 6.1 — Fix the hardcoded API URL in frontend

**The problem:** `frontend/src/api.js` has `http://127.0.0.1:5000/api` hardcoded. This won't work when deployed because the browser will try to reach `127.0.0.1` (localhost) instead of the EC2 server.

**The fix:** Change it to just `/api` (relative URL).

```bash
nano frontend/src/api.js
```

**Find this line (line 5):**
```js
  baseURL: "http://127.0.0.1:5000/api",
```

**Change it to:**
```js
  baseURL: "/api",
```

**Save and exit nano:** Press `Ctrl + X`, then `Y`, then `Enter`

> **Why `/api`?** When the frontend and backend are served from the same server, a relative URL like `/api` automatically goes to the same host. So if user opens `http://54.xx.xx.xx`, the API calls go to `http://54.xx.xx.xx/api`.

---

### Step 6.2 — Make backend serve the compiled frontend

**The problem:** Right now `server.js` only serves API routes. We need it to also serve the compiled React files.

```bash
nano backend/server.js
```

**Replace the ENTIRE file with this:**

```js
const express = require("express");
const dotenv = require("dotenv");
const cors = require("cors");
const path = require("path");

const connectDB = require("./config/db");

const userRoutes = require("./routes/userRoutes");

dotenv.config();
connectDB();

const app = express();

app.use(cors());
app.use(express.json());

app.use("/api/users", userRoutes);

// Serve the compiled React frontend
app.use(express.static(path.join(__dirname, "public")));

// For any route that isn't an API route, send index.html
app.get("*", (req, res) => {
  res.sendFile(path.join(__dirname, "public", "index.html"));
});

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

**Save and exit:** `Ctrl + X` → `Y` → `Enter`

> **What changed?**
> - Added `express.static(...)` — this serves CSS, JS, images from the `public` folder
> - Added `app.get("*", ...)` — any URL that isn't `/api/...` returns `index.html` (the React app)
> - The `public` folder will contain the built React files (the Dockerfile handles this)

---

## PART 7: Create the Dockerfile

### Step 7.1 — Create the file

```bash
nano Dockerfile
```

### Step 7.2 — Paste this content:

```dockerfile
# Stage 1: Build the React frontend
FROM node:20-alpine AS frontend-build

WORKDIR /app/frontend
COPY frontend/package.json frontend/package-lock.json* ./
RUN npm install
COPY frontend/ ./
RUN npm run build

# Stage 2: Production backend
FROM node:20-alpine

WORKDIR /app

COPY backend/package.json backend/package-lock.json* ./
RUN npm install --omit=dev

COPY backend/ ./

# Copy the built frontend into the backend's public folder
COPY --from=frontend-build /app/frontend/dist ./public

EXPOSE 5000

CMD ["node", "server.js"]
```

**Save and exit:** `Ctrl + X` → `Y` → `Enter`

> **What does this do?**
> - **Stage 1:** Takes the React code, runs `npm install` and `npm run build` → creates a `dist/` folder with HTML, CSS, JS
> - **Stage 2:** Takes the backend code, installs only production dependencies, then copies the built frontend from Stage 1 into a `public/` folder
> - The final image is small — only has the backend + pre-built frontend

---

## PART 8: Create docker-compose.yml

### Step 8.1 — Create the file

```bash
nano docker-compose.yml
```

### Step 8.2 — Paste this content:

```yaml
services:
  mongo:
    image: mongo:7
    container_name: mongo
    restart: unless-stopped
    volumes:
      - mongo-data:/data/db
    networks:
      - app-network

  app:
    build: .
    container_name: app
    restart: unless-stopped
    ports:
      - "80:5000"
    environment:
      - MONGO_URI=mongodb://mongo:27017/devops-app
      - PORT=5000
    depends_on:
      - mongo
    networks:
      - app-network

networks:
  app-network:
    driver: bridge

volumes:
  mongo-data:
```

**Save and exit:** `Ctrl + X` → `Y` → `Enter`

> **What does each part mean?**
> 
> | Config | Meaning |
> |--------|---------|
> | `mongo` service | Runs MongoDB from official image |
> | `mongo-data:/data/db` | Named volume — data survives even if container is deleted |
> | `app` service | Builds from our Dockerfile |
> | `ports: "80:5000"` | Maps EC2's port 80 to container's port 5000 |
> | `MONGO_URI=mongodb://mongo:27017/...` | `mongo` here is the container name — Docker networking resolves it |
> | `app-network` | Custom bridge network so containers can talk to each other |
> | `depends_on: mongo` | Start MongoDB before the app |
> | `restart: unless-stopped` | Auto-restart on crashes or EC2 reboot |

---

## PART 9: Build & Launch! 🚀

### Step 9.1 — Build and start everything

```bash
docker compose up -d --build
```

> This will take **3-5 minutes** the first time (downloading Node.js image, MongoDB image, installing npm packages, building React).

You'll see output like:
```
[+] Building ...
[+] Running 3/3
 ✔ Network devops-comprehensive-assignment_app-network  Created
 ✔ Container mongo                                       Started
 ✔ Container app                                         Started
```

### Step 9.2 — Verify containers are running

```bash
docker ps
```

You should see **exactly 2 containers**:
```
CONTAINER ID   IMAGE         STATUS        PORTS                  NAMES
xxxxxxxxxxxx   ...app        Up X min      0.0.0.0:80->5000/tcp   app
xxxxxxxxxxxx   mongo:7       Up X min      27017/tcp              mongo
```

---

## PART 10: Verify All Checks ✅

Run these one by one on the EC2:

```bash
# Check 01: Docker installed
docker --version

# Check 02: Docker daemon running
docker info

# Check 03: No pending upgrades
apt list --upgradable 2>/dev/null

# Check 04: Exactly 2 containers
docker ps

# Check 05: MongoDB is running
docker ps | grep mongo

# Check 06: App on port 80
docker ps | grep "0.0.0.0:80"

# Check 07: HTTP 200 at localhost
curl -s -o /dev/null -w "%{http_code}" http://localhost
# Should print: 200

# Check 08: Frontend HTML served
curl -s http://localhost | grep 'id="root"'
# Should show the HTML with div id="root"

# Check 09: API returns JSON with 200
curl -s -o /dev/null -w "%{http_code}" http://localhost/api/users
# Should print: 200

curl -s -I http://localhost/api/users | grep -i content-type
# Should show: application/json

# Check 10: Data persists across restarts
curl -X POST http://localhost/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","email":"test@test.com"}'

docker compose down
docker compose up -d

curl -s http://localhost/api/users
# Should still show the test user!
```

---

## PART 11: Test from Your Browser

1. Open your browser
2. Go to: `http://YOUR_EC2_PUBLIC_IP`
3. You should see the **User Management** app
4. Try adding a user — it should work!

---

## Quick Troubleshooting

| Problem | Solution |
|---------|----------|
| `docker compose` not found | Use `docker-compose` (with hyphen) or reinstall compose plugin |
| Port 80 not accessible from browser | Check Security Group has HTTP (port 80) rule with `0.0.0.0/0` |
| App shows error connecting to MongoDB | Check `MONGO_URI` uses `mongo` (container name), not `localhost` |
| Build fails at `npm run build` | Check you fixed the API URL in `frontend/src/api.js` |
| `curl localhost` gives connection refused | Run `docker logs app` to see what's wrong |
| Containers keep restarting | Run `docker logs app` or `docker logs mongo` to check errors |

---

## 📝 What to Explain to Your Teacher

When your teacher asks, explain these key concepts:

1. **Multi-stage Dockerfile** — "Stage 1 builds the React app, Stage 2 only has the backend + built frontend. This keeps the final image small."
2. **Why relative URL `/api`** — "Since both frontend and API are served by the same Express server, relative URLs work. The browser sends requests to the same host."
3. **Named volume** — "Data in MongoDB is stored in a named volume `mongo-data` which lives outside the container. Even if I delete the container, the data stays."
4. **Docker networking** — "Both containers are on a custom bridge network. They find each other by container name — `mongo` resolves to the MongoDB container's IP."
5. **Port mapping 80:5000** — "The host (EC2) listens on port 80 (default HTTP), and forwards traffic to the container's port 5000 where Express is running."
