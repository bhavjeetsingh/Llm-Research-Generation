import time
import random
from functools import wraps


def retry_on_rate_limit(max_retries=5, base_delay=2.0, max_delay=60.0):
    """Decorator that retries a function on rate limit (429) errors with exponential backoff."""
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            last_exception = None
            for attempt in range(max_retries):
                try:
                    return func(*args, **kwargs)
                except Exception as e:
                    error_str = str(e).lower()
                    is_rate_limit = (
                        "429" in error_str
                        or "rate limit" in error_str
                        or "rate_limit" in error_str
                        or "tokens per minute" in error_str
                    )
                    if not is_rate_limit:
                        raise
                    last_exception = e
                    if attempt < max_retries - 1:
                        delay = min(base_delay * (2 ** attempt) + random.uniform(0, 1), max_delay)
                        time.sleep(delay)
            raise last_exception
        return wrapper
    return decorator
