import re
from os import path


def parse_cmless(md):
    md = md.replace('’', "'")  # Replace curly apostrophes with straight ones
    md = md.replace('\\_', '_')  # Replace escaped underscores with plain ones
    md = re.sub(
        r"(?<!\n)\n(?!\\n)", " ", md
    )  # Replace newlines that aren't escaped with spaces
    pattern = r"## (.*?)\n(.*?)(?=## |\Z)"
    matches = re.findall(pattern, md, re.DOTALL)
    results = {key.strip(): value.strip() for key, value in matches}
    results['Name'] = re.search(r"^# (.*)", md).group(1).strip()
    return results


if __name__ == "__main__":
    directory = 'app/views/organizations/md'
    from os import listdir

    results = {}
    files = listdir(directory)
    for path in files:
        with open(f"{directory}/{path}", 'r') as f:
            markdown_text = f.read()
        parsed = parse_cmless(markdown_text)
        org_id = path.split('.')[0]
        results[org_id] = parsed

    with open('orgs.json', 'w', encoding='utf8') as f:
        from json import dump

        # f.write(dumps(results, indent=2, ensure_ascii=False).encode('utf-8'))
        dump(results, f, indent=2, ensure_ascii=False)
