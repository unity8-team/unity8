.pragma library

function clamp(value, min, max) {
    if (min <= max) {
        return Math.max(min, Math.min(max, value))
    } else {
        // swap min/max if min > max
        return clamp(value, max, min)
    }
}
