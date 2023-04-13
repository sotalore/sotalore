
export function formatSeconds(seconds) {
  const minutes = Math.floor(seconds / 60)
  const remainingSeconds = Math.floor(seconds % 60)
  if (minutes > 59) {
    const hours = Math.floor(minutes / 60)
    const remainingMinutes = Math.floor(minutes % 60)

    if (hours > 24) {
      const days = Math.floor(hours / 24)
      const remainingHours = Math.floor(hours % 24)
      return `${days}d ${remainingHours}h ${remainingMinutes}m`
    }
    return `${hours}:${pad(remainingMinutes)}:${pad(remainingSeconds)}`
  }
  return `${minutes}:${pad(remainingSeconds)}`
}

export function pad(n) {
  return n < 10 ? '0' + n : n
}
