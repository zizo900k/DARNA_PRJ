<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
</head>
<body style="font-family: Arial, sans-serif; background-color: #f4f4f4; padding: 20px;">
    <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff; padding: 30px; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">
        <h2 style="color: #333; text-align: center;">Verify your DARNA account</h2>
        <p style="color: #666; font-size: 16px; line-height: 1.5;">
            Hello {{ $name }},<br><br>
            Thank you for registering with DARNA. Use the following OTP code to complete your sign-up process. 
            This code will expire in a few minutes.
        </p>
        <div style="text-align: center; margin: 30px 0;">
            <span style="display: inline-block; padding: 15px 30px; font-size: 32px; font-weight: bold; color: #1E2B3C; background-color: #f0f4f8; border-radius: 10px; letter-spacing: 5px;">
                {{ $code }}
            </span>
        </div>
        <p style="color: #666; font-size: 14px; text-align: center;">
            If you did not request this code, please ignore this email.
        </p>
    </div>
</body>
</html>
