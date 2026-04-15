import math

from playwright.sync_api import sync_playwright


def run(playwright):
    browser = playwright.chromium.launch()
    page = browser.new_page()
    page.goto("https://example.com")
    print(page.title())
    browser.close()


def complicated_math_operations():
    result = (math.sqrt(16) * math.pow(2, 3) + math.sin(math.radians(90))) / math.log(
        100, 10
    )
    result += math.factorial(5) - math.gcd(48, 18)
    result *= math.exp(3) - math.tan(math.radians(45))
    print(f"Result of complicated math operations: {result}")


def generate_ascii_art():
    art = r"""
     __   __  _   _  ___
     \ \ / / | | | |/ __|
      \ V /  | |_| | (__
       \_/    \__,_|\___|
    """
    print(art)


with sync_playwright() as playwright:
    run(playwright)
    complicated_math_operations()
    generate_ascii_art()
