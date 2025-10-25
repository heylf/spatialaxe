#!/usr/bin/env python3

from bs4 import BeautifulSoup
from pathlib import Path

def clean_preview_html(input_html, output_mqc_html, height=800):
    """
    1. Cleans the Baysor preview HTML by removing the <div> containing
       <h2>Content</h2> and the <ul> list.
    2. Inlines the cleaned HTML directly into a MultiQC _mqc.html wrapper.
    """
    input_html = Path(input_html)
    output_mqc_html = Path(prefix)/output_mqc_html
    output_mqc_html.parent.mkdir(parents=True, exist_ok=True)

    # Step 1: Clean the HTML
    with open(input_html, 'r') as f:
        soup = BeautifulSoup(f, 'html.parser')

    for div in soup.find_all('div'):
        h2 = div.find('h2')
        ul = div.find('ul')
        if h2 and h2.get_text(strip=True) == 'Content' and ul:
            div.decompose()

    # Change all <h1> to <h3>
    for h1 in soup.find_all('h1'):
        h1.name = 'h3'

    cleaned_html_content = str(soup)

    # Step 2: Wrap and inline into MultiQC _mqc.html
    wrapper_content = f"""<!-- multiqc: section_name=Baysor Preview -->
<!-- multiqc: description=Interactive Baysor preview -->
{cleaned_html_content}
"""

    with open(output_mqc_html, 'w') as f:
        f.write(wrapper_content)


if __name__ == '__main__':
    preview_html = "${preview_html}"
    output_html = "preview_mqc.html"
    prefix = "${prefix}"

    clean_preview_html(
        preview_html,
        output_html
    )
    
    #Output versions.yml
    with open("versions.yml", "w") as f:
        f.write('"${task.process}":\\n')
        f.write('CLEAN_PREVIEW_HTML: "1.0.0"\\n')
