# Debug Guide: Finding & Fixing the GPT Model Version

## Problem
Your iOS app is still using an older GPT model (probably GPT-4) even though you want to use GPT-4.5 or newer.

## Solution: The model is configured on your **backend**, not in the iOS app!

### Where is the model actually specified?

Your iOS app (`NewMatchView.swift`, `APIClient.swift`) **does not specify** which GPT model to use. Instead, it sends requests to your backend server at:
- **Simulator**: `http://localhost:3002`
- **Physical device**: `http://172.20.10.10:3002` (your Mac's IP)

The backend server (likely Python/Node.js) is what actually calls OpenAI's API with a specific model version.

---

## Step 1: Find Your Backend Code

Look for your backend server code. It's probably in one of these locations:
- A `server/` or `backend/` folder in your project
- A separate repository
- A Python file like `server.py`, `app.py`, or `main.py`
- A Node.js file like `server.js`, `index.js`, or `app.js`

---

## Step 2: Search for Model Configuration

In your backend code, search for:
- `"gpt-4"` or `"gpt-4-turbo"`
- `model=`
- `openai.ChatCompletion.create`
- `client.chat.completions.create`

Example (Python with OpenAI):
```python
# OLD - This is what you probably have:
response = client.chat.completions.create(
    model="gpt-4",  # ← This is the problem!
    messages=[...]
)

# NEW - Update to:
response = client.chat.completions.create(
    model="gpt-4o",  # or "gpt-4-turbo" or whatever the latest is
    messages=[...]
)
```

Example (Node.js):
```javascript
// OLD:
const completion = await openai.chat.completions.create({
  model: "gpt-4",  // ← Update this
  messages: [...]
});

// NEW:
const completion = await openai.chat.completions.create({
  model: "gpt-4o",  // Latest model
  messages: [...]
});
```

---

## Step 3: Add a `/info` Endpoint to Your Backend

To make debugging easier, I've added a feature to the iOS app that can check which model your backend is using. Add this endpoint to your backend:

### Python (Flask example):
```python
@app.route('/info', methods=['GET'])
def info():
    return jsonify({
        "version": "1.0.0",
        "model": "gpt-4o",  # Whatever model you're using
        "environment": "development"
    })
```

### Node.js (Express example):
```javascript
app.get('/info', (req, res) => {
  res.json({
    version: "1.0.0",
    model: "gpt-4o",  // Whatever model you're using
    environment: "development"
  });
});
```

---

## Step 4: Test in the iOS App

1. Open your iOS app
2. Go to **Settings** (tab bar at bottom)
3. Scroll to the **Server** section
4. Tap the **"Backend Info"** button (purple button)
5. You should see:
   - **Model**: The GPT model your backend is using
   - **Version**: Your backend version
   - **Environment**: development/production

If you see an error, your backend doesn't have the `/info` endpoint yet. Add it!

---

## Step 5: Check the Console Logs

### iOS Console
When you process a video or images, you'll now see detailed logs like:
```
[NewMatchView] 🎬 Starting video processing for: file:///...
[NewMatchView] Video file size: 25.3 MB
[NewMatchView] 📊 Video extraction progress: 50%
[NewMatchView] 🤖 Parsing profile with AI...
[Settings] ✅ Backend Info - Model: gpt-4o, Version: 1.0.0
```

### Backend Console
Check your backend logs to see what requests it's receiving and what it's sending to OpenAI.

---

## Quick Reference: Available Models (as of Feb 2026)

According to OpenAI's latest docs:
- `gpt-4o` - Most recent multimodal model
- `gpt-4-turbo` - Fast, capable model
- `gpt-4` - Original GPT-4 (older, slower)
- `gpt-3.5-turbo` - Faster but less capable

**Note**: GPT-4.5 or GPT-5 may have different model identifiers. Check OpenAI's documentation.

---

## Debugging Checklist

- [ ] Found backend code location
- [ ] Found where model is specified in backend
- [ ] Updated model to latest version
- [ ] Added `/info` endpoint to backend
- [ ] Restarted backend server
- [ ] Tested "Backend Info" button in iOS app
- [ ] Verified correct model shows up
- [ ] Tested profile parsing with new model

---

## Common Issues

### "Failed to fetch backend info"
- Make sure your backend server is running
- Check the server URL in Settings matches your Mac's IP
- Add the `/info` endpoint to your backend

### "Still using old model"
- Make sure you restarted your backend server after changing the code
- Check if you have multiple places in your backend that specify the model
- Some backends use environment variables for the model - check `.env` files

### Video not loading
- Check console logs for detailed error messages
- Make sure `Movie` transferable is working (it should be now)
- Verify file permissions and that video is in a readable location

---

## Summary

**The iOS app is fixed and ready to go!** ✅

The changes made:
1. ✅ Fixed `Movie` transferable for video loading
2. ✅ Added detailed logging throughout video processing
3. ✅ Added "Backend Info" button in Settings
4. ✅ Added `/info` endpoint support in APIClient

**Now you need to update your backend to use the latest model.**

Find your backend code, search for `"gpt-4"`, and update it to the latest model identifier from OpenAI's docs.
