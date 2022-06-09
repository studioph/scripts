#!/usr/bin/env python3.9

import argparse
import csv
import logging
import os
import pathlib
from datetime import datetime

SIZE_UNIT = MEGABYTE = 1000 * 1000
LOG_LEVEL = logging.getLevelName(os.getenv("PY_LOG_LEVEL", "INFO"))

logging.basicConfig(level=LOG_LEVEL)
logger = logging.getLogger(__name__)


def setup_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--source",
        type=pathlib.Path,
        default=pathlib.Path(),
        help="The source folder to inventory (should be the root of the archive drive)",
    )
    parser.add_argument(
        "--dest",
        type=pathlib.Path,
        default=pathlib.Path("inventory.csv"),
        help="The destination file to write the inventory to",
    )
    return parser.parse_args()


def write_data(data: list[dict], dest: pathlib.Path):
    fields = ["path", "size", "date_created", "date_modified", "notes"]
    with dest.open("w", encoding="utf8") as output_file:
        logger.debug("Writing to %s", dest)
        writer = csv.DictWriter(output_file, fieldnames=fields, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(data)


def analyze_file(file: pathlib.Path, root: pathlib.Path) -> dict:
    logger.debug("Processing %s", file)
    stats = file.stat()
    return {
        "path": file.relative_to(root),
        "size": round(stats.st_size / SIZE_UNIT),
        "date_created": None,
        "date_modified": datetime.fromtimestamp(stats.st_mtime).isoformat(),
    }


def analyze_folder(folder: pathlib.Path, root: pathlib.Path) -> list[dict]:
    logger.info("Processing %s", folder)
    results = []
    for item in folder.iterdir():
        if item.is_dir():
            results += analyze_folder(item, root)
        elif item.is_file() and item.suffix != ".csv":
            results.append(analyze_file(item, root))
    return results


def main():
    args = setup_args()
    results = analyze_folder(args.source, args.source)
    write_data(results, args.dest)


if __name__ == "__main__":
    main()
