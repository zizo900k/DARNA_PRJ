<!DOCTYPE html>
<html>
<head>
    <title>Reset Your Password</title>
</head>
<body style="font-family: Arial, sans-serif; background-color: #f4f4f4; padding: 20px;">
    <div style="max-width: 600px; margin: 0 auto; background: #ffffff; padding: 30px; border-radius: 8px;">
        <h2 style="color: #2b6cb0;">Password Reset</h2>
        <p>Hello {{ $name }},</p>
        <p>You requested to reset your password. Use the following verification code to proceed:</p>
        <div style="margin: 20px 0; text-align: center;">
            <span style="font-size: 24px; font-weight: bold; padding: 10px 20px; background: #edf2f7; border-radius: 4px; letter-spacing: 5px;">{{ $code }}</span>
        </div>
        <p>If you didn't request this, you can safely ignore this email. Your password will remain unchanged.</p>
        <p>Best regards,<br>The Darna Team</p>
    </div>
</body>
</html>
