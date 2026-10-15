#!/usr/bin/env python3
"""
Pre-Flight Authentication Prover & Session Generator for Autonomous Screencasts.
Tests credentials, verifies logged-in DOM state, saves a proof screenshot,
and exports Playwright storage_state (auth.json) for recordings.

Usage:
    # 1. Automated login test:
    python3 verify_auth.py --login-url https://viscardibomboniere.com/mio-account --username "user@example.com" --password "secret"

    # 2. Interactive login (best for 2FA, CAPTCHA, or SSO):
    python3 verify_auth.py --login-url https://viscardibomboniere.com/mio-account --interactive

    # 3. From task_queue.json:
    python3 verify_auth.py --config task_queue.json
"""

import argparse
import asyncio
import json
import os
import sys

try:
    from playwright.async_api import async_playwright
except ImportError:
    print("[!] Playwright is required. Run: pip install playwright && playwright install chromium")
    sys.exit(1)

LOGGED_IN_SELECTORS = [
    "a[href*='logout']",
    "a[href*='esci']",
    "a:has-text('Logout')",
    "a:has-text('Esci')",
    "a:has-text('Disconnetti')",
    ".woocommerce-MyAccount-navigation",
    ".my-account-dashboard",
    ".user-profile",
    ".logged-in"
]

async def verify_and_save_auth(login_url: str, username: str = None, password: str = None,
                               work_dir: str = "screencasts/work", interactive: bool = False):
    os.makedirs(work_dir, exist_ok=True)
    auth_state_path = os.path.join(work_dir, "auth.json")
    proof_screenshot = os.path.join(work_dir, "auth_verified.png")

    print(f"[*] Starting authentication verification for: {login_url}")

    async with async_playwright() as p:
        # Launch headed if interactive, else headless
        browser = await p.chromium.launch(
            headless=not interactive,
            args=["--start-maximized", "--no-sandbox"]
        )

        context = await browser.new_context(
            viewport={"width": 1920, "height": 1080},
            locale="it-IT"
        )
        page = await context.new_page()

        print(f"[*] Navigating to login page: {login_url}...")
        await page.goto(login_url, wait_until="domcontentloaded")
        await page.wait_for_timeout(1000)

        # Auto-dismiss cookie popups
        try:
            cookie_btn = page.locator("button:has-text('Accetta'), button:has-text('Accetto'), #cookie-accept").first
            if await cookie_btn.is_visible(timeout=2000):
                await cookie_btn.click()
                await page.wait_for_timeout(500)
        except Exception:
            pass

        if interactive:
            print("\n" + "="*70)
            print(" [INTERACTIVE MODE ACTIVE]")
            print(" Please log in through the browser window (solve any 2FA or CAPTCHAs).")
            print(" The script is waiting until a logged-in state is detected...")
            print("="*70 + "\n")

            # Wait until logged-in indicator appears or user navigates
            authenticated = False
            for _ in range(120): # 2 minute timeout
                for sel in LOGGED_IN_SELECTORS:
                    if await page.locator(sel).first.is_visible():
                        authenticated = True
                        break
                if authenticated:
                    break
                await asyncio.sleep(1)

        else:
            # Automated login attempt
            if not username or not password:
                raise ValueError("Both --username and --password are required for automated login (or use --interactive).")

            print(f"[*] Attempting automated login as: {username}...")

            # Locate username input
            user_input = page.locator("input[type='email'], input[name='username'], input[name='log'], input[id*='user'], input[id*='email']").first
            await user_input.wait_for(state="visible", timeout=10000)
            await user_input.fill(username)

            # Locate password input
            pass_input = page.locator("input[type='password'], input[name='pwd'], input[name='password']").first
            await pass_input.wait_for(state="visible", timeout=10000)
            await pass_input.fill(password)

            # Locate submit button
            submit_btn = page.locator("button[type='submit'], input[type='submit'], button:has-text('Accedi'), button:has-text('Login')").first
            await submit_btn.click()
            await page.wait_for_load_state("domcontentloaded")
            await page.wait_for_timeout(3000)

        # Verify authentication
        print("[*] Proving authenticated state...")
        found_selector = None
        for sel in LOGGED_IN_SELECTORS:
            loc = page.locator(sel).first
            if await loc.is_visible():
                found_selector = sel
                break

        # Capture proof screenshot
        await page.screenshot(path=proof_screenshot, full_page=False)

        if found_selector or (page.url != login_url and "login" not in page.url.lower()):
            # Save session cookies & local storage
            await context.storage_state(path=auth_state_path)
            print(f"\n[✓✓✓] AUTHENTICATION PROVEN & VERIFIED!")
            if found_selector:
                print(f"  -> Detected authenticated indicator: '{found_selector}'")
            print(f"  -> Current authenticated URL: {page.url}")
            print(f"  -> Proof screenshot saved: {proof_screenshot}")
            print(f"  -> Persistent session state exported: {auth_state_path}")
            print("\nAll subsequent recordings will automatically reuse this session without logging in again!\n")
            await browser.close()
            return True
        else:
            print(f"\n[!] AUTHENTICATION FAILED: Could not confirm logged-in state.")
            print(f"  -> Current URL: {page.url}")
            print(f"  -> Screenshot of failed state saved: {proof_screenshot}")
            await browser.close()
            return False

def main():
    parser = argparse.ArgumentParser(description="Prove & Export Web Authentication for Screencasts")
    parser.add_argument("--login-url", default="https://viscardibomboniere.com/mio-account", help="Login URL")
    parser.add_argument("--username", default=os.getenv("VB_USERNAME"), help="Username or Email")
    parser.add_argument("--password", default=os.getenv("VB_PASSWORD"), help="Password")
    parser.add_argument("--config", help="Optional task_queue.json containing CREDENTIALS")
    parser.add_argument("--interactive", action="store_true", help="Open visible browser to log in manually (solves 2FA/CAPTCHA)")
    parser.add_argument("--work-dir", default="screencasts/work", help="Working directory for auth.json")

    args = parser.parse_args()

    login_url = args.login_url
    username = args.username
    password = args.password

    if args.config and os.path.exists(args.config):
        with open(args.config, "r", encoding="utf-8") as f:
            cfg = json.load(f)
            creds = cfg.get("CREDENTIALS", {})
            login_url = creds.get("login_url", login_url)
            username = creds.get("username_or_email", username)
            password = creds.get("password", password)

    success = asyncio.run(verify_and_save_auth(
        login_url=login_url,
        username=username,
        password=password,
        work_dir=args.work_dir,
        interactive=args.interactive
    ))

    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
