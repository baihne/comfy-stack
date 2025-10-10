# 🔐 Safe Tailscale Auth Key Usage

## Step 1: Get Your Auth Key Securely

1. **Visit Tailscale Admin Console**: https://login.tailscale.com/admin/settings/keys
2. **Click "Generate auth key"**
3. **Configure the key settings**:
   - ✅ **Reusable**: Check this (allows multiple VPS setups)
   - ✅ **Pre-approved**: Check this (automatic approval)
   - ❌ **Ephemeral**: Leave unchecked (persistent device)
   - **Expiry**: Set to 90 days or longer
   - **Tags**: Leave empty for personal use
4. **Copy the key** - It starts with `tskey-auth-` followed by random characters

## Step 2: Use the Key Safely

### ✅ Method 1: Direct Command Line (Recommended for testing)

```bash
# Connect to your VPS
ssh -i ~/.ssh/HyperStackCanada_Hyperstack ubuntu@YOUR-VPS-IP
ssh -i ~/.ssh/HyperStackNorway_Hyperstack ubuntu@YOUR-VPS-IP

# Clone and navigate
git clone https://github.com/baihne/comfy-stack && cd comfy-stack

# Use the key directly (replace YOUR_ACTUAL_KEY with your real key)
./deployment/deploy_comfyui_wan.sh I2V_A14B tskey-auth-kAbCdEf1234567890
```

### ✅ Method 2: Environment Variable (Most Secure)

```bash
# On your VPS, set the environment variable
export TAILSCALE_AUTH_KEY="tskey-auth-kAbCdEf1234567890"

# Then run without the key parameter
./deployment/deploy_comfyui_wan.sh I2V_A14B
```

### ✅ Method 3: Temporary File (For repeated use)

```bash
# Create a temporary file (will be deleted on reboot)
echo "tskey-auth-kAbCdEf1234567890" > /tmp/tailscale_key

# Use it in the script
./deployment/deploy_comfyui_wan.sh I2V_A14B "$(cat /tmp/tailscale_key)"

# Clean up immediately after
rm /tmp/tailscale_key
```

## Step 3: Key Security Best Practices

### ✅ DO:
- Generate a new key for each project/VPS if needed
- Set reasonable expiry dates (30-90 days)
- Delete/revoke keys you no longer need
- Use environment variables when possible
- Keep the key private and never share it

### ❌ DON'T:
- Put the key in scripts that go to GitHub
- Share the key in chat/email
- Leave the key in bash history
- Set overly long expiry dates (>1 year)
- Use the same key across many different projects

## Step 4: Verify Success

After running the deployment, you should see:
```
✅ Tailscale connected: 100.x.x.x
```

Test access:
```bash
# From any of your other devices with Tailscale
ssh ubuntu@100.x.x.x
# Open browser to: http://100.x.x.x:8188
```

## Key Rotation (Recommended every 90 days)

1. Generate a new auth key in Tailscale admin
2. Update your deployment scripts with the new key
3. Revoke the old key in Tailscale admin
4. Test that everything still works

## Troubleshooting

**Key not working?**
- Check it starts with `tskey-auth-`
- Verify it hasn't expired
- Make sure it's marked as "Pre-approved"
- Try generating a fresh key

**Still can't connect?**
- Check Tailscale admin console for your device
- Verify the VPS appears in your device list
- Run `sudo tailscale status` on the VPS

## Your Ready Commands

```bash
# 1. Get your key from: https://login.tailscale.com/admin/settings/keys

# 2. Connect to VPS (replace YOUR-CURRENT-VPS-IP with actual IP)
ssh -i ~/.ssh/HyperStackCanada_Hyperstack ubuntu@YOUR-CURRENT-VPS-IP

# 3. Deploy with your real key
cd comfy-stack
./deployment/deploy_comfyui_wan.sh I2V_A14B YOUR_REAL_TAILSCALE_KEY_HERE
```

## 🎯 Why This Solves Your Spot Instance Problem

**Problem**: Spot instance IPs change constantly
**Solution**: Tailscale gives you a **permanent IP (100.x.x.x)** that never changes!

✅ **VPS IP changes**: `203.0.113.10` → `198.51.100.20` → `...`
✅ **Tailscale IP stays**: `100.x.x.x` (always the same!)

**After setup, you'll always access via the same Tailscale IP regardless of spot instance changes!**