#!/usr/bin/env python3
import re
from models import Collection, Exhibit


def parse_cmless(file):
    with open(file, 'r', encoding='utf-8') as f:
        md = f.read()
    md = md.lstrip()  # Remove leading whitespace
    assert md.startswith('#'), "This is not a valid cmless file"

    md = md.replace('’', "'")  # Replace curly apostrophes with straight ones
    md = md.replace('\\_', '_')  # Replace escaped underscores with plain ones
    # md = re.sub(
    #     r"(?<!\n)\n(?!\\n)", " ", md
    # )  # Replace newlines that aren't escaped with spaces

    # Extract title from first H1
    title_match = re.search(r"^# (.*)", md)
    title = title_match.group(1).strip() if title_match else ""

    # Split by H2 sections - use word boundary to capture just the heading text
    pattern = r'^## (.+?)(?=\s|$)'
    parts = re.split(pattern, md, flags=re.MULTILINE)

    # Initialize results with title
    results = {'Title': title}

    # Split the first part to get the header
    header = parts[0].split('\n')[1:]
    # Join header lines into a single string
    header = ' '.join(header).strip()
    # If the header can be parsed as an integer, it is the Page number
    try:
        results['Page'] = int(header)
    except ValueError:
        pass

    # Add filename as slug - replace spaces with dashes and convert to lowercase
    slug = file.split('/')[-1].replace('.md', '').replace(' ', '-').lower()
    results['Slug'] = slug

    # Process the split parts - skip the first part (before first H2) and pair section names with content
    for i in range(1, len(parts), 2):
        if i + 1 < len(parts):
            section_name = parts[i].strip()
            section_content = parts[i + 1].lstrip().rstrip()
            results[section_name] = section_content or None

    return results


def parse_collections(directory):
    """
    Parses all cmless files in the given collections directory

    :param directory: The directory to parse
    :return: A dictionary of parsed cmless files
    """
    from os import listdir, path

    results = []
    files = [f for f in listdir(directory) if f.endswith('.md')]
    for file in files:
        try:
            parsed = parse_cmless(path.join(directory, file))
            parsed['Slug'] = file.replace('.md', '')
            # Validate with Collection model
            parsed = Collection(**parsed)
        except Exception as e:
            print(f"Error parsing {file}: {e}")
            continue

        results.append(parsed)
    return results

def parse_exhibits(directory: str) -> list[Exhibit]:
    """
    Parses all cmless exhibits in the given directory

    :param directory: The directory to parse
    :return: A list of Exhibit pages
    """
    from os import listdir, path


    exhibits = []
    files = [f for f in listdir(directory) if f.endswith('.md')]
    for file in files:
        try:
            slug = file.replace('.md', '')
            parsed = parse_cmless(path.join(directory, file))
            parsed['Page'] = parsed.get('Page', 0)
            parsed['Slug'] = slug
            # Validate with Exhibit model
            exhibit = Exhibit(**parsed)
            if path.isdir(path.join(directory, slug)):
                print('Parsing exhibit directory:', slug)
                exhibit_path = path.join(directory, slug)
                exhibit_files = [f for f in listdir(exhibit_path) if f.endswith('.md')]

                for page in exhibit_files:
                    try:
                        parsed = parse_cmless(path.join(directory, slug, page))
                        parsed['Slug'] = page.replace('.md', '')
                        # Validate with Exhibit model
                        child_page = Exhibit(**parsed)
                        if exhibit.children is None:
                            exhibit.children = []
                        exhibit.children.append(child_page)
                    except Exception as x:
                        print(f"Error parsing {file}: {x}")
                        continue
            if exhibit.children:
                exhibit.children.sort(key=lambda x: (x.page if x.page is not None else -1))
            exhibits.append(exhibit)
        
        except Exception as e:
            print(f"Error parsing {slug}: {e}")
            continue

    return exhibits
