# CrowdStrike and Elastic Agent Management Script

This project provides a simple, interactive Bash script to install, uninstall, and manage CrowdStrike Falcon and Elastic Agents on Linux systems. It supports CentOS, Ubuntu, and Debian distributions.

**Features**
 - Check if agents are installed
 - Install CrowdStrike Falcon agent only
 - Install Elastic agent only
 - Install both agents
 - Uninstall CrowdStrike Falcon agent only
 - Uninstall Elastic agent only
 - Uninstall both agents
 - Restart the agents individually or both at once

**Prerequisites**
 - A Linux system running CentOS, Ubuntu, or Debian
 - curl installed on the system
 - Supported versions of OpenSSL installed on the system

**Usage**
1. Clone the repository or download the script file Install_Uninstall_Agents.sh.

<pre><code>git clone https://github.com/hpimentao/CrowdStrike-Elastic-Agents-Mgmt.git
cd CrowdStrike-Elastic-Agents_Mgmt</pre></code>

2. Make the script executable.
<pre><code>sudo chmod +x Install-Uninstall-CrowdStrike-Elastic-Agents-Linux.sh</pre></code>

3. Edit the script file to set your CrowdStrike CID and Elastic SIEM enrollment token.
<pre><code>sudo nano Install-Uninstall-CrowdStrike-Elastic-Agents-Linux.sh</pre></code>
Find the following lines:
<pre><code>CID=""
ENROLLMENT_TOKEN=""</pre></code>
Replace the empty quotes with your CrowdStrike CID and Elastic SIEM enrollment token.

4. Run the script.
<pre><code>sudo ./Install-Uninstall-CrowdStrike-Elastic-Agents-Linux.sh</pre></code>
Follow the on-screen prompts to manage CrowdStrike Falcon and Elastic Agents.

**Troubleshooting**

If you encounter any issues, please check the Install-Uninstall-CrowdStrike-Elastic-Agents-Linux.log file for more information. This log file is located in the same directory as the script file.
Contributing

We welcome contributions to this project. Please open an issue or submit a pull request on GitHub.
License

This project is released under the MIT License. Please refer to the LICENSE file for more information.
