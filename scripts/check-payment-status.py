#!/usr/bin/env python3
"""
Check Payment Status Script
Usage: python check-payment-status.py <payment_id>
"""

import sys
import requests
import json
from datetime import datetime

# Configuration
API_URL = "https://api.payments.example.com/v1"
API_KEY = "YOUR_API_KEY"  # Replace with actual API key or use environment variable

def check_payment_status(payment_id):
    """Check the status of a payment"""

    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json"
    }

    try:
        print(f"Checking payment: {payment_id}")
        print("-" * 50)

        # Make API request
        response = requests.get(
            f"{API_URL}/payments/{payment_id}",
            headers=headers,
            timeout=10
        )

        if response.status_code == 200:
            payment = response.json()

            # Display payment details
            print(f"\nPayment ID: {payment['id']}")
            print(f"Status: {payment['status']}")
            print(f"Amount: {payment['amount']/100:.2f} {payment['currency']}")
            print(f"Created: {payment['created_at']}")
            print(f"Updated: {payment.get('updated_at', 'N/A')}")
            print(f"Customer ID: {payment.get('customer_id', 'N/A')}")
            print(f"Payment Method: {payment.get('payment_method', 'N/A')}")

            if payment.get('description'):
                print(f"Description: {payment['description']}")

            if payment.get('metadata'):
                print(f"\nMetadata:")
                for key, value in payment['metadata'].items():
                    print(f"  {key}: {value}")

            # Status indicator
            status = payment['status']
            if status == 'succeeded':
                print(f"\n✓ Payment succeeded")
            elif status == 'failed':
                print(f"\n✗ Payment failed")
                if payment.get('error'):
                    print(f"Error: {payment['error'].get('message', 'Unknown error')}")
            elif status == 'pending':
                print(f"\n⏳ Payment pending")
            else:
                print(f"\n⚠ Payment status: {status}")

            return 0

        elif response.status_code == 404:
            print(f"\n✗ Payment not found: {payment_id}")
            return 1

        elif response.status_code == 401:
            print(f"\n✗ Authentication failed. Check your API key.")
            return 1

        else:
            print(f"\n✗ Error: {response.status_code}")
            print(response.text)
            return 1

    except requests.exceptions.Timeout:
        print(f"\n✗ Request timed out")
        return 1

    except requests.exceptions.RequestException as e:
        print(f"\n✗ Request failed: {e}")
        return 1

    except Exception as e:
        print(f"\n✗ Unexpected error: {e}")
        return 1

def main():
    if len(sys.argv) != 2:
        print("Usage: python check-payment-status.py <payment_id>")
        print("Example: python check-payment-status.py pay_1234567890")
        sys.exit(1)

    payment_id = sys.argv[1]

    if not payment_id.startswith('pay_'):
        print("Warning: Payment ID should start with 'pay_'")

    exit_code = check_payment_status(payment_id)
    sys.exit(exit_code)

if __name__ == "__main__":
    main()
