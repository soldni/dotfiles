import os

def driver():
    for root, subdir, files in os.walk(os.getcwd()):
        if '.git' in root:
            continue

        for fn in files:
            fp = os.path.join(root, fn)

            with file(fp) as f:
                content = f.read()
                content = content.replace('\r', '')
            with file(fp, 'wb') as f:
                f.write(content)

if __name__ == '__main__':
    driver()
