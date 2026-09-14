<x-mail::message>
# Admin Authorization Required

Hello,

A login attempt was made to the **Patapoa Admin Portal** using your credentials. For your security, we require you to authorize this session.

<x-mail::button :url="$url">
Authorize This Session
</x-mail::button>

If you did not make this request, please ignore this email or contact security.

**Note:** this link will expire in 15 minutes.

Thanks,<br>
{{ config('app.name') }} Security Team
</x-mail::message>
