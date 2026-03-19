#!/usr/bin/env python3
"""
Payment Processor - Sample Implementation
This is a simplified version of the payment processing logic
"""

import logging
import time
from enum import Enum
from typing import Dict, Optional
from dataclasses import dataclass
import requests

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class PaymentStatus(Enum):
    """Payment status enumeration"""
    PENDING = "pending"
    PROCESSING = "processing"
    SUCCEEDED = "succeeded"
    FAILED = "failed"
    REFUNDED = "refunded"


class PaymentProvider(Enum):
    """Payment provider enumeration"""
    STRIPE = "stripe"
    PAYPAL = "paypal"
    BANK_PARTNER = "bank_partner"


@dataclass
class PaymentRequest:
    """Payment request data"""
    amount: int  # Amount in cents
    currency: str
    payment_method: str
    payment_method_id: str
    customer_id: str
    description: Optional[str] = None
    metadata: Optional[Dict] = None


@dataclass
class PaymentResponse:
    """Payment response data"""
    id: str
    status: PaymentStatus
    amount: int
    currency: str
    provider: PaymentProvider
    error: Optional[str] = None


class PaymentProcessor:
    """Main payment processor class"""

    def __init__(self, config: Dict):
        self.config = config
        self.stripe_api_key = config.get('stripe_api_key')
        self.paypal_client_id = config.get('paypal_client_id')
        self.paypal_client_secret = config.get('paypal_client_secret')

    def process_payment(self, request: PaymentRequest) -> PaymentResponse:
        """
        Process a payment request

        Args:
            request: PaymentRequest object

        Returns:
            PaymentResponse object
        """
        logger.info(f"Processing payment: amount={request.amount}, currency={request.currency}")

        try:
            # Step 1: Validate request
            self._validate_payment_request(request)

            # Step 2: Select payment provider
            provider = self._select_provider(request.payment_method)
            logger.info(f"Selected provider: {provider.value}")

            # Step 3: Check fraud
            if not self._check_fraud(request):
                logger.warning(f"Fraud check failed for customer: {request.customer_id}")
                return PaymentResponse(
                    id=self._generate_payment_id(),
                    status=PaymentStatus.FAILED,
                    amount=request.amount,
                    currency=request.currency,
                    provider=provider,
                    error="Payment failed fraud check"
                )

            # Step 4: Process with provider
            if provider == PaymentProvider.STRIPE:
                response = self._process_stripe_payment(request)
            elif provider == PaymentProvider.PAYPAL:
                response = self._process_paypal_payment(request)
            else:
                response = self._process_bank_payment(request)

            logger.info(f"Payment processed: id={response.id}, status={response.status.value}")
            return response

        except Exception as e:
            logger.error(f"Payment processing failed: {e}")
            return PaymentResponse(
                id=self._generate_payment_id(),
                status=PaymentStatus.FAILED,
                amount=request.amount,
                currency=request.currency,
                provider=PaymentProvider.STRIPE,
                error=str(e)
            )

    def _validate_payment_request(self, request: PaymentRequest):
        """Validate payment request"""
        if request.amount <= 0:
            raise ValueError("Amount must be positive")

        if not request.currency:
            raise ValueError("Currency is required")

        if not request.payment_method_id:
            raise ValueError("Payment method ID is required")

        if not request.customer_id:
            raise ValueError("Customer ID is required")

    def _select_provider(self, payment_method: str) -> PaymentProvider:
        """Select payment provider based on payment method"""
        if payment_method in ['card', 'credit_card']:
            return PaymentProvider.STRIPE
        elif payment_method == 'paypal':
            return PaymentProvider.PAYPAL
        elif payment_method in ['ach', 'wire']:
            return PaymentProvider.BANK_PARTNER
        else:
            return PaymentProvider.STRIPE  # Default

    def _check_fraud(self, request: PaymentRequest) -> bool:
        """
        Check for fraud
        In production, this would call a fraud detection service
        """
        # Simplified fraud check
        if request.amount > 1000000:  # $10,000
            logger.warning(f"High amount transaction: {request.amount}")
            # In production, would do more checks

        return True  # Simplified - always pass

    def _process_stripe_payment(self, request: PaymentRequest) -> PaymentResponse:
        """Process payment with Stripe"""
        logger.info("Processing Stripe payment")

        # In production, this would call Stripe API
        # Simulated for demo purposes
        payment_id = self._generate_payment_id()

        # Simulate API call
        time.sleep(0.1)

        # Simulate success (90% success rate)
        import random
        if random.random() < 0.9:
            return PaymentResponse(
                id=payment_id,
                status=PaymentStatus.SUCCEEDED,
                amount=request.amount,
                currency=request.currency,
                provider=PaymentProvider.STRIPE
            )
        else:
            return PaymentResponse(
                id=payment_id,
                status=PaymentStatus.FAILED,
                amount=request.amount,
                currency=request.currency,
                provider=PaymentProvider.STRIPE,
                error="Card declined"
            )

    def _process_paypal_payment(self, request: PaymentRequest) -> PaymentResponse:
        """Process payment with PayPal"""
        logger.info("Processing PayPal payment")

        payment_id = self._generate_payment_id()

        # Simulate API call
        time.sleep(0.15)

        return PaymentResponse(
            id=payment_id,
            status=PaymentStatus.SUCCEEDED,
            amount=request.amount,
            currency=request.currency,
            provider=PaymentProvider.PAYPAL
        )

    def _process_bank_payment(self, request: PaymentRequest) -> PaymentResponse:
        """Process payment with bank partner"""
        logger.info("Processing bank payment")

        payment_id = self._generate_payment_id()

        # Bank payments are typically async
        return PaymentResponse(
            id=payment_id,
            status=PaymentStatus.PENDING,
            amount=request.amount,
            currency=request.currency,
            provider=PaymentProvider.BANK_PARTNER
        )

    def _generate_payment_id(self) -> str:
        """Generate a unique payment ID"""
        import uuid
        return f"pay_{uuid.uuid4().hex[:16]}"


def main():
    """Example usage"""

    # Configuration
    config = {
        'stripe_api_key': 'sk_test_1234567890',
        'paypal_client_id': 'paypal_client_id',
        'paypal_client_secret': 'paypal_client_secret'
    }

    # Create processor
    processor = PaymentProcessor(config)

    # Example payment request
    request = PaymentRequest(
        amount=10000,  # $100.00
        currency='USD',
        payment_method='card',
        payment_method_id='pm_1234567890',
        customer_id='cus_1234567890',
        description='Test payment',
        metadata={'order_id': '12345'}
    )

    # Process payment
    response = processor.process_payment(request)

    # Display result
    print(f"\nPayment Result:")
    print(f"  ID: {response.id}")
    print(f"  Status: {response.status.value}")
    print(f"  Amount: ${response.amount/100:.2f}")
    print(f"  Provider: {response.provider.value}")
    if response.error:
        print(f"  Error: {response.error}")


if __name__ == "__main__":
    main()
