#!/usr/bin/env python3
import re
from .models import Collection


def parse_cmless(file):
    with open(file, 'r', encoding='utf-8') as f:
        md = f.read()
    md = md.lstrip()  # Remove leading whitespace
    assert md.startswith('#'), "This is not a valid cmless file"

    md = md.replace('’', "'")  # Replace curly apostrophes with straight ones
    md = md.replace('\\_', '_')  # Replace escaped underscores with plain ones
    md = re.sub(
        r"(?<!\n)\n(?!\\n)", " ", md
    )  # Replace newlines that aren't escaped with spaces
    pattern = r"## (.*?)\n(.*?)(?=## |\Z)"
    matches = re.findall(pattern, md, re.DOTALL)
    results = {key.strip(): value.strip() for key, value in matches}
    results['Title'] = re.search(r"^# (.*)", md).group(1).strip()
    return results


def parse_dir(directory):
    """
    Parses all cmless files in the given directory

    :param directory: The directory to parse
    :return: A dictionary of parsed cmless files
    """
    from os import listdir, path

    results = {}
    files = [f for f in listdir(directory) if f.endswith('.md')]
    for file in files:
        try:
            parsed = parse_cmless(path.join(directory, file))
            parsed['Slug'] = file.replace('.md', '')
            parsed = Collection(**parsed)  # Validate with Collection model
        except Exception as e:
            print(f"Error parsing {file}: {e}")
            continue

        results[file.replace('.md', '')] = parsed
    return results


if __name__ == '__main__':
    # Get all Organization cmless files
    orgs = parse_dir('app/views/organizations/md')

    # Save the results to orgs.json
    with open('orgs.json', 'w', encoding='utf8') as f:
        from json import dump

        dump(orgs, f, indent=2, ensure_ascii=False)
