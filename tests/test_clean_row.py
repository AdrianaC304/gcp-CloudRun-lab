"""
Local tests for Challenge 1 (clean_row).

Run from the repo root:
    pip install -r function/on_upload/requirements.txt pytest
    python -m pytest tests/

By default they test YOUR code in function/on_upload/main.py.
To check the reference solution instead:
    SOLUTION=1 python -m pytest tests/
"""
import importlib.util
import os
import pathlib
import sys
from unittest import mock

ROOT = pathlib.Path(__file__).resolve().parents[1]
FOLDER = "solutions/function/on_upload" if os.environ.get("SOLUTION") else "function/on_upload"

# The module creates GCP clients at import time: replace them with mocks so
# the tests run on a laptop without credentials.
sys.modules.setdefault("google.cloud.bigquery", mock.MagicMock())
sys.modules.setdefault("google.cloud.storage", mock.MagicMock())
spec = importlib.util.spec_from_file_location("on_upload_main", ROOT / FOLDER / "main.py")
main = importlib.util.module_from_spec(spec)
with mock.patch("google.cloud.bigquery.Client"), mock.patch("google.cloud.storage.Client"):
    spec.loader.exec_module(main)
clean_row = main.clean_row


def row(**overrides):
    base = {
        "order_id": "ORD-00001",
        "order_date": "2026-10-26",
        "country": "ES",
        "product": "Wireless Mouse",
        "quantity": "2",
        "unit_price": "24.9",
    }
    base.update(overrides)
    return base


def test_good_row_is_kept_with_types():
    out = clean_row(row())
    assert out["quantity"] == 2 and isinstance(out["quantity"], int)
    assert out["unit_price"] == 24.9
    assert out["country"] == "ES"


def test_empty_product_is_dropped():
    assert clean_row(row(product="")) is None
    assert clean_row(row(product="   ")) is None


def test_negative_or_zero_quantity_is_dropped():
    assert clean_row(row(quantity="-1")) is None
    assert clean_row(row(quantity="0")) is None


def test_zero_price_is_dropped():
    assert clean_row(row(unit_price="0")) is None


def test_country_is_normalised():
    assert clean_row(row(country=" es"))["country"] == "ES"


def test_bad_country_is_dropped():
    assert clean_row(row(country="Spain")) is None


def test_non_numeric_values_do_not_crash():
    assert clean_row(row(quantity="abc")) is None
    assert clean_row(row(unit_price="")) is None
