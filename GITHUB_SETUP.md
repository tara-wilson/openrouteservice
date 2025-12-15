# GitHub Setup for OpenRouteService US Deployment

This guide helps you set up your own GitHub repository to sync changes between your local machine and Hetzner server.

## Step 1: Create a New GitHub Repository

1. Go to https://github.com/new
2. Create a new repository (e.g., `openrouteservice-us` or `openrouteservice-hetzner`)
3. **Do NOT** initialize with README, .gitignore, or license (we already have these)
4. Copy the repository URL (e.g., `https://github.com/YOUR_USERNAME/openrouteservice-us.git`)

## Step 2: Add Your Repository as a Remote

On your local machine:

```bash
# Add your repo as a new remote (we'll keep 'origin' pointing to the original repo)
git remote add myrepo https://github.com/YOUR_USERNAME/openrouteservice-us.git

# Or if you prefer to use SSH:
git remote add myrepo git@github.com:YOUR_USERNAME/openrouteservice-us.git

# Verify remotes
git remote -v
```

You should see:
- `origin` → original GIScience repo
- `myrepo` → your new repo

## Step 3: Commit and Push Your Changes

```bash
# Commit the new files
git commit -m "Add US deployment configuration for Hetzner server"

# Push to your repository
git push myrepo main

# Or if your branch is named differently:
git push myrepo main:main
```

## Step 4: Set Up on Hetzner Server

On your Hetzner server:

```bash
# Clone your repository
git clone https://github.com/YOUR_USERNAME/openrouteservice-us.git
cd openrouteservice-us

# Or if you want to clone into a specific directory:
git clone https://github.com/YOUR_USERNAME/openrouteservice-us.git /path/to/openrouteservice
```

## Step 5: Workflow for Updates

### On Your Local Machine (Making Changes):

```bash
# Make your changes to files
# ... edit files ...

# Stage changes
git add .

# Commit
git commit -m "Description of changes"

# Push to your repo
git push myrepo main
```

### On Hetzner Server (Pulling Updates):

```bash
# Navigate to the repo directory
cd /path/to/openrouteservice-us

# Pull latest changes
git pull

# If you made local changes, you might need to stash them first:
git stash
git pull
git stash pop
```

## Alternative: Use SSH Keys (Recommended)

For easier authentication, set up SSH keys:

### On Your Local Machine:

```bash
# Generate SSH key if you don't have one
ssh-keygen -t ed25519 -C "your_email@example.com"

# Copy public key
cat ~/.ssh/id_ed25519.pub
```

### Add to GitHub:

1. Go to GitHub → Settings → SSH and GPG keys
2. Click "New SSH key"
3. Paste your public key

### Update Remote URL:

```bash
# Change remote to use SSH
git remote set-url myrepo git@github.com:YOUR_USERNAME/openrouteservice-us.git
```

### On Hetzner Server:

```bash
# Generate SSH key on server
ssh-keygen -t ed25519 -C "hetzner-server"

# Add to GitHub (same process as above)

# Clone using SSH
git clone git@github.com:YOUR_USERNAME/openrouteservice-us.git
```

## Quick Reference Commands

### Local Machine:
```bash
# Push changes
git add .
git commit -m "Your message"
git push myrepo main

# Pull updates from original repo (if needed)
git pull origin main
```

### Hetzner Server:
```bash
# Pull latest changes
cd /path/to/openrouteservice-us
git pull

# If you need to reset to match remote exactly:
git fetch myrepo
git reset --hard myrepo/main
```

## Troubleshooting

### If you get "permission denied" on push:
- Check that you've added your SSH key to GitHub
- Or use HTTPS with a personal access token

### If you want to sync with the original repo:
```bash
# Add upstream (original repo) if not already added
git remote add upstream https://github.com/GIScience/openrouteservice.git

# Fetch updates from original repo
git fetch upstream

# Merge updates into your branch
git merge upstream/main
```

### If you want to keep your repo in sync with upstream:
```bash
# Create a sync script
cat > sync-upstream.sh << 'EOF'
#!/bin/bash
git fetch upstream
git merge upstream/main
git push myrepo main
EOF

chmod +x sync-upstream.sh
```

