import sys
from pathlib import Path
from config import validate_paths, test_folder, train_folder
from prepare_dataset import prepare_dataset
from evaluate_models import evaluate_models

def run_pipeline():
    print("=" * 60)
    print("ML PIPELINE - AUTOMATED WORKFLOW")
    print("=" * 60)
    print()

    print("Step 1: Validating configuration...")
    try:
        validate_paths()
        print("✓ Configuration validated\n")
    except FileNotFoundError as e:
        print(f"✗ Configuration error: {e}")
        sys.exit(1)

    print("Step 2: Preparing dataset...")
    print("-" * 60)
    try:
        prepare_dataset()
        print("-" * 60)
        print("✓ Dataset prepared\n")
    except Exception as e:
        print(f"✗ Dataset preparation failed: {e}")
        sys.exit(1)

    print("Step 3: Evaluating models...")
    print("-" * 60)
    try:
        evaluate_models()
        print("-" * 60)
        print("✓ Models evaluated\n")
    except Exception as e:
        print(f"✗ Model evaluation failed: {e}")
        sys.exit(1)

    print("=" * 60)
    print("PIPELINE COMPLETED SUCCESSFULLY")
    print("=" * 60)
    print()
    print("Summary:")
    print(f"  Test folder: {test_folder}")
    print(f"  Train folder: {train_folder}")
    print("  Results: D:\\Results\\m1_results.xlsx, m2_results.xlsx")
    print()
    print("Standalone utility: python check_duplicates.py")
    print()

if __name__ == "__main__":
    run_pipeline()
