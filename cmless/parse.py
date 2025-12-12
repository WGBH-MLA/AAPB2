#!/usr/bin/env python3
import re
from .models import Collection, Exhibit, Author


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
                exhibit.children.sort(
                    key=lambda x: (x.page if x.page is not None else -1)
                )
            exhibits.append(exhibit)

        except Exception as e:
            print(f"Error parsing {slug}: {e}")
            continue

    return exhibits


def parse_cmless_thumbnail(markdown_string: str) -> list[dict[str, str]]:
    """
    Parse a markdown string containing cmless images into a list of objects.

    Args:
        markdown_string (str): The markdown string to parse

    Returns:
        List[Dict[str, str]]: List of dictionaries with 'title' and 'image_url' keys
    """
    # Pattern to match ![title](url)
    pattern = r'\!\[([^\]]*)\]\(([^\)]*)\)'
    matches = re.findall(pattern, markdown_string)

    cmless_images = []
    for match in matches:
        title, url = match
        cmless_images.append({'title': title.strip(), 'url': url.strip().split(' ')[0]})

    return cmless_images


def parse_featured_markdown(markdown_string: str) -> list[dict[str, str]]:
    """
    Parse a markdown string containing featured items into a list of objects.

    Expected format: [![title](image_url)](link_url)

    Args:
        markdown_string (str): The markdown string to parse

    Returns:
        List[Dict[str, str]]: List of dictionaries with 'title', 'image_url', and 'link_url' keys
    """
    # Pattern to match [![title](image_url)](link_url)
    pattern = r'\[\!\[([^\]]*)\]\(([^\)]*)\)\]\(([^\)]*)\)'

    matches = re.findall(pattern, markdown_string)

    featured_items = []
    for match in matches:
        title, image_url, link_url = match
        guid = link_url.split('/')[-1].split('#')[0]  # Extract guid from link_url
        start_time = link_url.split('#at_')[-1] if '#at_' in link_url else None
        featured_items.append(
            {
                'title': title.strip(),
                # 'thumbnail': image_url.strip(),
                'guids': guid.strip(),
                'start_time': (
                    start_time.strip().replace('_s', '') if start_time else None
                ),
            }
        )

    return featured_items


def parse_records_markdown(markdown_string: str) -> list[str]:
    """
    Parse a markdown string containing records into a list of record guids.

    Expected format:
        - [](/catalog/guid)

    Args:
        markdown_string (str): The markdown string to parse

    Returns:
        List[str]: List of record guids
    """
    # Pattern to match [Record Title](record_url)
    pattern = r'- \[.*?\]\(/catalog/cpb-aacip-([a-zA-Z0-9_-]+)\)'
    matches = re.findall(pattern, markdown_string)
    record_guids = [f'cpb-aacip-{match.strip()}' for match in matches]
    return record_guids


def pasre_authors_markdown(markdown_string: str) -> list[Author]:
    """
    Parse a markdown string containing authors into a list of author names.

    Expected format:
        - <img src="url/to/source"/>
          <a class="name">Author Name</a>
          <a class="title">Author Title</a>

    Args:
        markdown_string (str): The markdown string to parse

    Returns:
        List[Author]: List of Author objects
    """
    # Pattern to match - Author Name
    from bs4 import BeautifulSoup

    parts = markdown_string.split('\n- ')
    authors = []
    for part in parts:
        soup = BeautifulSoup(part, 'html.parser')
        author_tag = soup.find('a', class_='name')
        if not author_tag:
            print('No author name found in part:', part)
            continue
        author = Author(name=author_tag.text.strip())
        title_tag = soup.find('a', class_='title')
        if title_tag:
            author.title = title_tag.text.strip()
        image_tag = soup.find('img')
        if image_tag:
            author.image = image_tag.get('src')
        authors.append(author)
    return authors


def markdownify(text: str) -> str:
    """
    Converts markdown text to HTML string
    """
    from markdown import markdown

    return str(markdown(text))
