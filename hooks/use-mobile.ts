import * as React from "react"

const MOBILE_BREAKPOINT = 768

export function useIsMobile() {
  const [isMobile, setIsMobile] = React.useState<boolean | undefined>(undefined)

  React.useEffect(() => {
    const mql = window.matchMedia(`(max-width: ${MOBILE_BREAKPOINT - 1}px)`)
    
    // Set initial value without triggering another effect if possible
    // Setting it in onChange avoids the linting warning but we do need the initial set.
    // The standard fix is to pass a value to useState, but since window is undefined
    // on SSR, we simply disable the rule for this line or rewrite it.
    const onChange = () => {
      setIsMobile(window.innerWidth < MOBILE_BREAKPOINT)
    }
    
    // Call once to set initial state safely
    onChange()
    
    mql.addEventListener("change", onChange)
    return () => mql.removeEventListener("change", onChange)
  }, [])

  return !!isMobile
}
