import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { JWT } from "https://esm.sh/google-auth-library@8.7.0"

serve(async (req) => {
  try {
    const payload = await req.json()
    const record = payload.record
    const old_record = payload.old_record

    // 🌟 UPDATE 1: Yahan roomId ko room_id kar diya gaya hai
    if (record && record.room_id && record.room_id !== old_record?.room_id) {
      
      const clientEmail = Deno.env.get("FIREBASE_CLIENT_EMAIL")
      // Ye replace function zaroori hai taaki key ka format sahi rahe
      const privateKey = Deno.env.get("FIREBASE_PRIVATE_KEY")?.replace(/\\n/g, '\n')
      const projectId = Deno.env.get("FIREBASE_PROJECT_ID")

      if (!clientEmail || !privateKey || !projectId) {
        throw new Error("❌ Firebase Secrets missing in Supabase!")
      }

      // Firebase se authentication token lena
      const jwt = new JWT({
        email: clientEmail,
        key: privateKey,
        scopes: ['https://www.googleapis.com/auth/cloud-platform'],
      })

      const token = await jwt.getAccessToken()
      const fcmUrl = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`

      // 🌟 Ye wahi MAGIC payload hai jo app kill hone par bhi notification layega 🌟
      const message = {
        message: {
          topic: `tournament_${record.id}`,
          notification: {
            title: "🎮 Room Ready! Join Fast",
            // 🌟 UPDATE 2: Yahan room_id aur room_password set kar diya hai
            body: `Room ID: ${record.room_id} | Password: ${record.room_password}`
          },
          android: {
            priority: "high" 
          }
        }
      }

      // Firebase ko message bhejna
      const response = await fetch(fcmUrl, {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${token.token}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(message),
      })

      const responseData = await response.json()
      console.log("✅ FCM Response:", responseData)

      return new Response(JSON.stringify({ success: true, message: "Notification Sent to Battle Master players!" }), {
        headers: { "Content-Type": "application/json" },
        status: 200,
      })
    }

    // Agar room_id update nahi hui toh kuch mat karo
    return new Response(JSON.stringify({ success: true, message: "No room_id update detected." }), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    })

  } catch (error) {
    console.error("❌ Error:", error.message)
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { "Content-Type": "application/json" },
      status: 400,
    })
  }
})