<!DOCTYPE html>
<html lang="en" xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <title>Welcome to DARNA</title>
    <!--[if mso]>
    <noscript>
        <xml>
            <o:OfficeDocumentSettings>
                <o:PixelsPerInch>96</o:PixelsPerInch>
            </o:OfficeDocumentSettings>
        </xml>
    </noscript>
    <![endif]-->
    <style type="text/css">
        /* Reset */
        body, table, td, a { -webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; }
        table, td { mso-table-lspace: 0pt; mso-table-rspace: 0pt; }
        img { -ms-interpolation-mode: bicubic; border: 0; height: auto; line-height: 100%; outline: none; text-decoration: none; }
        body { margin: 0; padding: 0; width: 100% !important; height: 100% !important; }

        /* Dark mode support */
        @media (prefers-color-scheme: dark) {
            .email-bg { background-color: #1a1a2e !important; }
            .email-card { background-color: #16213e !important; }
            .text-dark { color: #e0e0e0 !important; }
            .text-muted { color: #b0b0b0 !important; }
            .divider { border-color: #2a2a4a !important; }
        }

        /* Responsive */
        @media only screen and (max-width: 600px) {
            .email-container { width: 100% !important; padding: 12px !important; }
            .email-card { padding: 28px 20px !important; }
            .logo-img { width: 80px !important; height: 80px !important; }
            .heading { font-size: 24px !important; }
            .subtext { font-size: 15px !important; }
            .cta-btn { padding: 14px 32px !important; font-size: 15px !important; }
        }
    </style>
</head>
<body style="margin: 0; padding: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;">

<!-- Background wrapper -->
<table role="presentation" cellpadding="0" cellspacing="0" width="100%" style="background: linear-gradient(135deg, #0f2027 0%, #203a43 50%, #2c5364 100%); background-color: #1a1a2e;" class="email-bg">
    <tr>
        <td align="center" style="padding: 40px 16px;">

            <!-- Email container -->
            <table role="presentation" cellpadding="0" cellspacing="0" width="560" class="email-container" style="max-width: 560px; width: 100%;">

                <!-- Logo -->
                <tr>
                    <td align="center" style="padding-bottom: 32px;">
                        <img src="{{ $message->embed(public_path('images/darna-logo.png')) }}"
                             alt="DARNA Logo"
                             class="logo-img"
                             width="100"
                             height="100"
                             style="width: 100px; height: 100px; border-radius: 22px; box-shadow: 0 8px 32px rgba(0,0,0,0.3);">
                    </td>
                </tr>

                <!-- Main Card -->
                <tr>
                    <td>
                        <table role="presentation" cellpadding="0" cellspacing="0" width="100%" class="email-card" style="background-color: #ffffff; border-radius: 20px; box-shadow: 0 20px 60px rgba(0,0,0,0.15); overflow: hidden;">

                            <!-- Green accent bar -->
                            <tr>
                                <td style="height: 5px; background: linear-gradient(90deg, #1abc9c, #16a085, #1abc9c);"></td>
                            </tr>

                            <!-- Content -->
                            <tr>
                                <td style="padding: 48px 40px 40px 40px;">

                                    <!-- Greeting -->
                                    <table role="presentation" cellpadding="0" cellspacing="0" width="100%">
                                        <tr>
                                            <td align="center" style="padding-bottom: 8px;">
                                                <span style="font-size: 40px; line-height: 1;">👋</span>
                                            </td>
                                        </tr>
                                        <tr>
                                            <td align="center" style="padding-bottom: 6px;">
                                                <h1 class="heading" style="margin: 0; font-size: 28px; font-weight: 800; color: #1a1a2e; letter-spacing: -0.5px;">
                                                    Welcome to DARNA!
                                                </h1>
                                            </td>
                                        </tr>
                                        <tr>
                                            <td align="center" style="padding-bottom: 28px;">
                                                <p class="text-muted" style="margin: 0; font-size: 16px; color: #666666;">
                                                    Hello <strong style="color: #1abc9c;">{{ $user->name }}</strong>, we're thrilled to have you!
                                                </p>
                                            </td>
                                        </tr>
                                    </table>

                                    <!-- Divider -->
                                    <table role="presentation" cellpadding="0" cellspacing="0" width="100%">
                                        <tr>
                                            <td style="padding-bottom: 28px;">
                                                <hr class="divider" style="border: none; border-top: 1px solid #f0f0f0; margin: 0;">
                                            </td>
                                        </tr>
                                    </table>

                                    <!-- Body text -->
                                    <table role="presentation" cellpadding="0" cellspacing="0" width="100%">
                                        <tr>
                                            <td class="text-dark" style="font-size: 15px; line-height: 1.7; color: #444444; padding-bottom: 12px;">
                                                Your account has been successfully created. You're now part of Morocco's premier real estate community.
                                            </td>
                                        </tr>
                                        <tr>
                                            <td class="text-dark" style="font-size: 15px; line-height: 1.7; color: #444444; padding-bottom: 28px;">
                                                With DARNA, you can:
                                            </td>
                                        </tr>
                                    </table>

                                    <!-- Feature list -->
                                    <table role="presentation" cellpadding="0" cellspacing="0" width="100%" style="padding-bottom: 32px;">
                                        <tr>
                                            <td style="padding: 12px 16px; background-color: #f8fffe; border-radius: 12px; margin-bottom: 8px;">
                                                <table role="presentation" cellpadding="0" cellspacing="0" width="100%">
                                                    <tr>
                                                        <td width="36" style="font-size: 20px; vertical-align: top; padding-top: 2px;">🏠</td>
                                                        <td class="text-dark" style="font-size: 14px; color: #444444; line-height: 1.6;">
                                                            <strong>Browse properties</strong> — Explore houses, apartments, villas, and more across Morocco
                                                        </td>
                                                    </tr>
                                                </table>
                                            </td>
                                        </tr>
                                        <tr><td style="height: 8px;"></td></tr>
                                        <tr>
                                            <td style="padding: 12px 16px; background-color: #f8fffe; border-radius: 12px;">
                                                <table role="presentation" cellpadding="0" cellspacing="0" width="100%">
                                                    <tr>
                                                        <td width="36" style="font-size: 20px; vertical-align: top; padding-top: 2px;">💬</td>
                                                        <td class="text-dark" style="font-size: 14px; color: #444444; line-height: 1.6;">
                                                            <strong>Contact owners directly</strong> — Chat instantly with property owners and agents
                                                        </td>
                                                    </tr>
                                                </table>
                                            </td>
                                        </tr>
                                        <tr><td style="height: 8px;"></td></tr>
                                        <tr>
                                            <td style="padding: 12px 16px; background-color: #f8fffe; border-radius: 12px;">
                                                <table role="presentation" cellpadding="0" cellspacing="0" width="100%">
                                                    <tr>
                                                        <td width="36" style="font-size: 20px; vertical-align: top; padding-top: 2px;">⭐</td>
                                                        <td class="text-dark" style="font-size: 14px; color: #444444; line-height: 1.6;">
                                                            <strong>Save favorites & review</strong> — Bookmark listings and share your experience
                                                        </td>
                                                    </tr>
                                                </table>
                                            </td>
                                        </tr>
                                    </table>

                                    <!-- CTA Button -->
                                    <table role="presentation" cellpadding="0" cellspacing="0" width="100%">
                                        <tr>
                                            <td align="center" style="padding: 8px 0 32px 0;">
                                                <a href="{{ $appUrl }}"
                                                   class="cta-btn"
                                                   target="_blank"
                                                   style="display: inline-block; padding: 16px 40px; background: linear-gradient(135deg, #1abc9c, #16a085); color: #ffffff; font-size: 16px; font-weight: 700; text-decoration: none; border-radius: 12px; box-shadow: 0 4px 15px rgba(26,188,156,0.4); letter-spacing: 0.3px;">
                                                    Explore Properties →
                                                </a>
                                            </td>
                                        </tr>
                                    </table>

                                    <!-- Divider -->
                                    <table role="presentation" cellpadding="0" cellspacing="0" width="100%">
                                        <tr>
                                            <td>
                                                <hr class="divider" style="border: none; border-top: 1px solid #f0f0f0; margin: 0;">
                                            </td>
                                        </tr>
                                    </table>

                                </td>
                            </tr>

                            <!-- Footer inside card -->
                            <tr>
                                <td style="padding: 24px 40px 32px 40px; text-align: center;">
                                    <p class="text-muted" style="margin: 0; font-size: 13px; color: #999999; line-height: 1.6;">
                                        Thank you for joining us!<br>
                                        <strong style="color: #1abc9c;">The DARNA Team</strong>
                                    </p>
                                </td>
                            </tr>

                        </table>
                    </td>
                </tr>

                <!-- Bottom footer -->
                <tr>
                    <td align="center" style="padding: 28px 16px 12px 16px;">
                        <p style="margin: 0; font-size: 12px; color: rgba(255,255,255,0.5); line-height: 1.6;">
                            © {{ date('Y') }} DARNA — Morocco's Real Estate Platform<br>
                            You received this email because you registered on DARNA.
                        </p>
                    </td>
                </tr>

            </table>

        </td>
    </tr>
</table>

</body>
</html>
