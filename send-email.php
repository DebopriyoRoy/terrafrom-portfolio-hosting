<?php

require "vendor/autoload.php";

use PHPMailer\PHPMailer\PHPMailer;

header('Content-Type: application/json; charset=UTF-8');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed.']);
    exit;
}

$contentType = $_SERVER['CONTENT_TYPE'] ?? '';
$payload = [];

if (stripos($contentType, 'application/json') !== false) {
    $raw = file_get_contents('php://input');
    $decoded = json_decode($raw, true);
    if (is_array($decoded)) {
        $payload = $decoded;
    }
} else {
    $payload = $_POST;
}

$name = trim($payload['name'] ?? '');
$email = trim($payload['email'] ?? '');
$subject = trim($payload['subject'] ?? '');
$message = trim($payload['message'] ?? '');

if ($name === '' || $email === '' || $subject === '' || $message === '') {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Please fill in all required fields.']);
    exit;
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Please enter a valid email address.']);
    exit;
}

$mail = new PHPMailer(true);

try {
    $mail->isSMTP();
    $mail->Host       = 'smtp.gmail.com';
    $mail->SMTPAuth   = true;
    $mail->Username   = 'debopriyo.ca@gmail.com';
    $mail->Password   = getenv('SMTP_PASSWORD');
    $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
    $mail->Port       = 587;
    $mail->CharSet    = 'UTF-8';

    $mail->setFrom($mail->Username, 'Contact Form - Your Website');
    $mail->addReplyTo($email, $name);
    $mail->addAddress('debopriyo.inbox@gmail.com', 'Debopriyo');

    $mail->isHTML(true);
    $mail->Subject = 'New Contact: ' . $subject;

    $safeName = htmlspecialchars($name, ENT_QUOTES, 'UTF-8');
    $safeEmail = htmlspecialchars($email, ENT_QUOTES, 'UTF-8');
    $safeSubject = htmlspecialchars($subject, ENT_QUOTES, 'UTF-8');
    $safeMessage = nl2br(htmlspecialchars($message, ENT_QUOTES, 'UTF-8'));
    $receivedOn = date('F j, Y \a\t g:i A');

    $mail->Body = '
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <h2 style="color: #333; border-bottom: 2px solid #4CAF50; padding-bottom: 10px;">New Contact Form Submission</h2>

        <div style="background-color: #f9f9f9; padding: 20px; border-radius: 5px; margin: 20px 0;">
            <p><strong>Name:</strong> ' . $safeName . '</p>
            <p><strong>Email:</strong> ' . $safeEmail . '</p>
            <p><strong>Subject:</strong> ' . $safeSubject . '</p>
        </div>

        <div style="margin: 20px 0;">
            <h3 style="color: #333;">Message:</h3>
            <div style="background-color: #fff; padding: 15px; border-left: 4px solid #4CAF50; margin: 10px 0;">
                ' . $safeMessage . '
            </div>
        </div>

        <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd; font-size: 12px; color: #666;">
            <p>This email was sent from your website contact form.</p>
            <p>Received on: ' . $receivedOn . '</p>
        </div>
    </div>';

    $lineBreak = PHP_EOL;
    $mail->AltBody = "New Contact Form Submission" . $lineBreak . $lineBreak .
                     "Name: " . $name . $lineBreak .
                     "Email: " . $email . $lineBreak .
                     "Subject: " . $subject . $lineBreak . $lineBreak .
                     "Message:" . $lineBreak . $message . $lineBreak . $lineBreak .
                     "Received on: " . $receivedOn;

    $mail->addCustomHeader('X-Mailer', 'Website Contact Form');
    $mail->addCustomHeader('X-Priority', '3');
    $mail->addCustomHeader('Importance', 'Normal');
    $mail->addCustomHeader('X-MSMail-Priority', 'Normal');

    $host = $_SERVER['HTTP_HOST'] ?? 'localhost';
    $mail->addCustomHeader('List-Unsubscribe', '<mailto:noreply@' . $host . '>');
    $mail->addCustomHeader('Precedence', 'bulk');

    $mail->send();

    echo json_encode(['success' => true, 'message' => 'Message sent successfully.']);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Message could not be sent.',
        'error' => $mail->ErrorInfo
    ]);
}
?>
