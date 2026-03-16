import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

const headers = { 'Content-Type': 'application/json' }

serve(async (req) => {
  const body = await req.json()
  const user = body.user
  const otp = body.sms?.otp ?? body.otp

  // Normalize phone: remove spaces, dashes, leading +
  let phone = user.phone.replace(/[\s\-]/g, '')
  if (phone.startsWith('+')) phone = phone.slice(1)

  const apiKey = Deno.env.get('TWOFACTOR_API_KEY')!

  const url = `https://2factor.in/API/V1/${apiKey}/SMS/${phone}/${otp}/OTP?medium=sms`

  const res = await fetch(url)
  const data = await res.json()

  if (data.Status !== 'Success') {
    console.error('2Factor error:', data)
    return new Response(JSON.stringify({ error: data.Details }), { status: 500, headers })
  }

  return new Response(JSON.stringify({ success: true }), { status: 200, headers })
})
