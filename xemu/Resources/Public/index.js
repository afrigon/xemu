function main() {
    const dropZone = document.getElementById('drop-zone');
      const fileInput = document.getElementById('fileInput');
      const fileList = document.getElementById('file-list');

      // Highlight the drop zone when dragging a file over it
      dropZone.addEventListener('dragover', (e) => {
        e.preventDefault();
        dropZone.classList.add('dragover');
      });

      // Remove highlight when drag leaves
      dropZone.addEventListener('dragleave', () => {
        dropZone.classList.remove('dragover');
      });

      // Handle drop event
      dropZone.addEventListener('drop', (e) => {
        e.preventDefault();
        dropZone.classList.remove('dragover');
        const files = e.dataTransfer.files;
        handleFiles(files);
      });

      // Handle file selection through input click
      dropZone.addEventListener('click', () => {
        fileInput.click();
      });

      fileInput.addEventListener('change', () => {
        const files = fileInput.files;
        handleFiles(files);
      });

      // Function to handle files and upload them
      function handleFiles(files) {
        fileList.innerHTML = ''; // Clear file list

        Array.from(files).forEach(file => {
          const listItem = document.createElement('div');
          listItem.className = 'file-item';
          listItem.textContent = `File: ${file.name} (${file.size} bytes)`;
          fileList.appendChild(listItem);

          // Upload each file via POST request
          uploadFile(file);
        });
      }

      // Function to upload a file
    function uploadFile(file) {
        const formData = new FormData();
        formData.append('file', file);
        
        fetch('/upload', {
            method: 'POST',
            body: formData
        })
        .then(response => {
            if (response.ok) {
                console.log(`${file.name} uploaded successfully.`);
            } else {
                console.error(`${file.name} failed to upload.`);
            }
        })
        .catch(error => {
            console.error(`Error uploading ${file.name}:`, error);
        });
    }
}

document.addEventListener('DOMContentLoaded', main)

