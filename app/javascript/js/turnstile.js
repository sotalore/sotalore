export default function turnstilePageLoad() {
    if (typeof turnstile !== 'undefined') {
        turnstile.implicitRender()
    }
}