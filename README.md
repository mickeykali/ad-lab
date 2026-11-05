# Active Directory Home Lab

> **Status:** 🚧 In progress. Domain controller built and users provisioned with PowerShell. Group Policy and a domain-joined client are next.

## Overview
A home lab that simulates a small company's Windows identity environment. The goal is hands-on practice with **identity and access management (IAM)**: building a domain, organizing users into OUs, managing security groups, and automating user provisioning.

## Lab Environment
| Component | Details |
|---|---|
| Host | Windows PC running VirtualBox |
| Domain Controller | Windows Server 2022 Standard Evaluation (Desktop Experience), hostname `DC01` |
| VM resources | 2 vCPU, 4 GB RAM, 50 GB disk |
| Domain | `lab.local` (NetBIOS: `LAB`) |
| Network | VirtualBox NAT (default) |

## Skills Demonstrated
- Installing Windows Server 2022 in a virtual machine
- Installing the AD DS role and promoting a server to a domain controller (new forest, integrated DNS)
- Designing an OU structure by department
- Creating security groups and organizing users by role
- Automating user provisioning with PowerShell from a CSV
- Enforcing a password change at first logon for new accounts

## Build Steps

### 1. Install Windows Server 2022
Created a VirtualBox VM, installed Windows Server 2022 with Desktop Experience, and renamed the server to `DC01`.

![Server Manager after install](screenshots/01-server-install.png)

### 2. Install AD DS and create the domain
Added the **Active Directory Domain Services** role in Server Manager, then promoted the server to a domain controller in a new forest, `lab.local`. DNS was installed as part of the promotion.

![AD DS and DNS roles running](screenshots/02-adds-dns-roles.png)

### 3. Provision users with PowerShell
Wrote [`scripts/Create-LabUsers.ps1`](scripts/Create-LabUsers.ps1), which reads [`scripts/users.csv`](scripts/users.csv) and for each user:
- creates the department OU if it doesn't exist (`IT`, `HR`, `Sales`)
- creates a department security group (`SG-IT`, `SG-HR`, `SG-Sales`) in a `Groups` OU
- creates the user (username = first initial + last name) in their department OU
- adds the user to their department group
- requires a password change at first logon

Result: 4 OUs, 3 security groups, 8 users.

![PowerShell script output](screenshots/04-powershell-users.png)

### 4. Verify in Active Directory Users and Computers
Confirmed the OU structure and users in ADUC.

![OU structure with IT users](screenshots/03-ou-structure.png)

## What I Learned
- Installing a role (AD DS) and promoting a server to a domain controller are two separate steps.
- Promoting the first DC creates the forest and domain and sets up DNS, which Active Directory depends on.
- Scripting user creation from a CSV is faster and more consistent than creating accounts by hand, and the CSV acts as a record of who was provisioned.
- VirtualBox's unattended install failed with a "cannot find license terms" error. I fixed it by swapping the auto-install disc for the real ISO and installing manually.

## Next Steps
- [ ] Group Policy: password and account lockout policy
- [ ] Join a Windows 11 client to the domain and log in as a domain user
- [ ] Help-desk tasks: password resets, account unlocks, disabling a departed user
- [ ] Delegate password-reset rights to a help-desk group (least privilege)
- [ ] Forward Windows Security logs to Splunk (see my SOC lab)
