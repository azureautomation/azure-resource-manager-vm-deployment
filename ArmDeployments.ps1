#############################################################################
#                                     			 		    #
#   This Sample Code is provided for the purpose of illustration only       #
#   and is not intended to be used in a production environment.  THIS       #
#   SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT    #
#   WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT    #
#   LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS     #
#   FOR A PARTICULAR PURPOSE.  We grant You a nonexclusive, royalty-free    #
#   right to use and modify the Sample Code and to reproduce and distribute #
#   the object code form of the Sample Code, provided that You agree:       #
#   (i) to not use Our name, logo, or trademarks to market Your software    #
#   product in which the Sample Code is embedded; (ii) to include a valid   #
#   copyright notice on Your software product in which the Sample Code is   #
#   embedded; and (iii) to indemnify, hold harmless, and defend Us and      #
#   Our suppliers from and against any claims or lawsuits, including        #
#   attorneys' fees, that arise or result from the use or distribution      #
#   of the Sample Code.                                                     #
#                                     			 		    #
#   Version 2.1						            #
#                                     			 		    #
#############################################################################


#requires -modules @{ModuleName="AzureRM.Resources"; ModuleVersion="4.0.0"}
#requires -version 5
	[void][reflection.assembly]::Load('System, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
	[void][reflection.assembly]::Load('System.Windows.Forms, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')

$AutoCred = Get-Credential -UserName "AzureAutomate@<Domain Name.com>" -Message "Please provide login credentials for your azure subscription, this cannot be a Microsoft live account."
Add-AzureRmAccount -Credential $AutoCred -ErrorAction Stop

#region Variables
$Form 		= New-Object System.Windows.Forms.Form

$listboxRSG = New-Object System.Windows.Forms.ListBox
$listboxStorage  = New-Object System.Windows.Forms.ListBox

$Grid_VMs = New-Object System.Windows.Forms.DataGridView
$Global:VMs = @()
$Global:VM_Configs = @()

$cmb_Subscription = New-Object System.Windows.Forms.ComboBox
$cmb_RSG = New-Object System.Windows.Forms.ComboBox
$cmb_Location = New-Object System.Windows.Forms.ComboBox
$cmb_Storage = New-Object System.Windows.Forms.ComboBox
$cmb_Vnetwork = New-Object System.Windows.Forms.ComboBox
$cmb_Subnet = New-Object System.Windows.Forms.ComboBox
$cmb_PublicIP = New-Object System.Windows.Forms.ComboBox

$cmb_VMSize = New-Object System.Windows.Forms.ComboBox
$cmb_VMpublisher = New-Object System.Windows.Forms.ComboBox
$cmb_VMImageOffer = New-Object System.Windows.Forms.ComboBox
$cmb_VMImageSku = New-Object System.Windows.Forms.ComboBox
$cmb_VMVersion = New-Object System.Windows.Forms.ComboBox
$cmb_AVSet     = New-Object System.Windows.Forms.ComboBox

$txt_VMName = New-Object System.Windows.Forms.TextBox
$btn_AddConfig = New-Object System.Windows.Forms.Button
$btn_Deploy_VM = New-Object System.Windows.Forms.Button
$btn_Credentials = New-Object System.Windows.Forms.Button
$Global:Cred = '' #Used to store Credentials for local admin accounts
$label_Subscription = New-Object System.Windows.Forms.Label
$label_VMpulisher = New-Object System.Windows.Forms.Label
$label_Location = New-Object System.Windows.Forms.Label
$label_Rsg = New-Object System.Windows.Forms.Label
$label_StorageAccount = New-Object System.Windows.Forms.Label
$label_VnetWork = New-Object System.Windows.Forms.Label
$label_Subnet = New-Object System.Windows.Forms.Label
#$label_NSG = New-Object System.Windows.Forms.Label
$label_PiPC = New-Object System.Windows.Forms.CheckBox
$label_PiP = New-Object System.Windows.Forms.Label
$label_VMSize = New-Object System.Windows.Forms.Label
$label_VMname = New-Object System.Windows.Forms.Label
$label_VMImageOffer = New-Object System.Windows.Forms.Label
$label_VMImageSku = New-Object System.Windows.Forms.Label
$label_VMVersion = New-Object System.Windows.Forms.Label
$label_Avset = New-Object System.Windows.Forms.Label


$btn_Deploy_VM.Enabled = $false

$h_Location = @{}
$h_RSGroups = @{'New...' = ''}
$h_Storage  = @{'New...' = ''}
$h_NSG      = @{'New...' = ''}
$h_Networks = @{'New...' = ''}
$h_Pip      = @{'New...' = ''}
$h_AVS      = @{'New...' = '';'None' = 'None'}


#endregion
#region functions

Function load-cmb
{
Param([System.Collections.Hashtable]$Data,[System.Windows.Forms.ComboBox]$Control,$Default=$true)

$Control.Items.Clear()
$data.Keys | %{if (($default -eq $false) -and ($_ -eq 'New...') ){}Else{$Control.Items.Add($_)}}

}

Function Load-Subnet
{
Param($Network)
        $cmb_Subnet.Items.Clear() | Out-Null
      
        $h_Networks."$($Network)".Subnets | Select Name,AddressPrefix,@{name='DisplayName';E={("$($_.Name) [$($_.AddressPrefix)] NSG: $($_.NetworkSecurityGroup)" )}} | %{$cmb_Subnet.Items.Add($_.DisplayName) }

}

Function Display-Form
{Param([string]$Form)

$Popup = New-Object System.Windows.Forms.Form

$P_Lbl_Location = New-Object System.Windows.Forms.Label
$P_Lbl_Name = New-Object System.Windows.Forms.Label
$p_Txt_Name = New-Object System.Windows.Forms.TextBox
$p_Btn_Add  = New-Object System.Windows.Forms.Button


$P_Lbl_Location.Width = 400
$P_Lbl_Name.Width     = 150
$p_Txt_Name.Width     = 200
$p_Btn_Add.Width      = 80
$p_Btn_Add.Height     = 40


$P_Lbl_Location.Location = '10, 10'
$P_Lbl_Name.Location     = '10, 40'


$p_Txt_Name.Location     = '200, 40'

$P_Lbl_Location.Text     = "Location                              $($cmb_Location.SelectedItem)"
$p_Btn_Add.Text          = 'Add'
$P_Lbl_Name.Text         = 'Name'



$P_Lbl_Location,$P_Lbl_Name,$P_Lbl_Location,$P_Lbl_Name,$p_Txt_Name,$p_Btn_Add |`
 %{$Popup.Controls.Add($_)}
Switch ($Form)
    {
        'ResourceGroup' {
                        $Popup.Size = '500, 200'
                        $p_Btn_Add.Location      = '200, 70'
                        $Popup.Text = "ResourceGroup"    
                        $p_Btn_Add.add_click({
                                            $h_RSGroups."$($p_Txt_Name.Text)" = @{ResourceGroupName = $p_Txt_Name.Text ; Location = $cmb_Location.SelectedItem ; Create = 1}
                                            load-cmb -Data $h_RSGroups -Control $cmb_RSG
                                            $Popup.Close()
                                            })
                        }
        'StorageAccount' {
                        $P_Lbl_RSGName = New-Object System.Windows.Forms.Label
                        $P_cmb_RSG = New-Object System.Windows.Forms.ComboBox
                        $Popup.Size = '500, 250'
                        $P_Lbl_RSGName,$P_cmb_RSG |  %{$Popup.Controls.Add($_)}

                        $P_Lbl_RSGName.Width     = 150
                        $P_Lbl_RSGName.Location  = '10, 70'
                        $P_Lbl_RSGName.Text      = "ResourceGroup"
                        $P_cmb_RSG.Location      = '200, 70'
                        $P_cmb_RSG.Width         = '200'
                        $p_Btn_Add.Location      = '200, 100'

                        $Popup.Text = "StorageAccount"    
                        load-cmb -Data $h_RSGroups -Control $P_cmb_RSG -Default $false
                        
                        $p_Btn_Add.add_click({
                                            If ((Test-AzureName -Storage $p_Txt_Name.Text) -eq $false)
                                            {
                                            $h_Storage."$($p_Txt_Name.Text)" = @{StorageAccountName = ($p_Txt_Name.Text).ToLower().Replace(" ",'') ;ResourceGroupName = $P_cmb_RSG.SelectedItem ; Location = $cmb_Location.SelectedItem ; Create = 1}
                                            load-cmb -Data $h_Storage -Control $cmb_Storage
                                            $p_Txt_Name.ForeColor = [System.Drawing.Color]::Black
                                            $Popup.Close()
                                            }
                                            ELSE
                                            {
                                             [System.Windows.Forms.MessageBox]::Show("The StorageAccount Name $($p_Txt_Name.Text) is not available, please use something else.","Error",[System.Windows.Forms.MessageBoxButtons]::OK)
                                            $p_Txt_Name.ForeColor = [System.Drawing.Color]::Red
                                            }
                                            })
                        }
        'VirtualNetwork' {
                        $p_Btn_Subnet_add  = New-Object System.Windows.Forms.Button
                        $p_Btn_Subnet_del  = New-Object System.Windows.Forms.Button
                        $P_txt_Address     = New-Object System.Windows.Forms.TextBox
                        $P_lbl_Address     = New-Object System.Windows.Forms.Label
                        $P_cmb_RSG         = New-Object System.Windows.Forms.ComboBox
                        $P_Lbl_RSGName     = New-Object System.Windows.Forms.Label
                        $p_lst_Subnet      = New-Object System.Windows.Forms.ListBox
                        $P_lbl_Subnet      = New-Object System.Windows.Forms.Label
                        $P_lbl_SubnetName  = New-Object System.Windows.Forms.Label
                        $P_lbl_SubnetBlock = New-Object System.Windows.Forms.Label
                        $P_txt_SubnetBlock = New-Object System.Windows.Forms.TextBox
                        $P_txt_SubnetName  = New-Object System.Windows.Forms.TextBox
                        $P_cmb_NSG         = New-Object System.Windows.Forms.ComboBox
                        $P_label_NSG         = New-Object System.Windows.Forms.Label

                        $P_cmb_RSG.Location      = '200, 70'
                        $P_cmb_RSG.Width         = '200'

                        $P_lbl_Address,$P_lbl_Address,$P_cmb_RSG,$P_txt_Address,$P_Lbl_RSGName,$p_lst_Subnet, $P_lbl_Subnet,$P_lbl_SubnetName,$P_lbl_SubnetBlock,$P_txt_SubnetBlock,$P_txt_SubnetName,$p_Btn_Subnet_add,$p_Btn_Subnet_add,$p_Btn_Subnet_del,$P_label_NSG,$P_cmb_NSG |  %{$Popup.Controls.Add($_)}

                        $P_Lbl_RSGName.Width     = 150
                        $P_Lbl_RSGName.Location  = '10, 70'
                        $P_Lbl_RSGName.Text      = "ResourceGroup"

                        $P_lbl_Address.Width     = 150
                        $P_lbl_Address.Location  = '10, 100'
                        $P_lbl_Address.Text      = "Address Block"
                        $p_i = 1
                        $p_Txt_Name.MaxLength    = 18
                        $P_txt_Address.Width     = 150
                        $P_txt_Address.Location  = '200, 100'
                        $P_txt_Address.Text      = "10.0.0.0/16"

                        $P_lbl_SubnetName.Width     = 150
                        $P_lbl_SubnetName.Location  = '10, 130'
                        $P_lbl_SubnetName.Text      = "Subnet Name"

                        $P_txt_SubnetName.Width     = 150
                        $P_txt_SubnetName.Location  = '200, 130'
                        $P_txt_SubnetName.Text      = "Subnet$($p_i)"

                        $P_lbl_SubnetBlock.Width     = 150
                        $P_lbl_SubnetBlock.Location  = '10, 160'
                        $P_lbl_SubnetBlock.Text      = "Subnet Range"

                        $P_txt_SubnetBlock.Width     = 150
                        $P_txt_SubnetBlock.Location  = '200, 160'
                        $P_txt_SubnetBlock.Text      = "10.0.$($p_i).0/24"

                        $P_label_NSG.Width = 180
                        $P_label_NSG.Location = '10, 190'
                        $P_label_NSG.Text = "Network Security Group"

                        $P_cmb_NSG.Width = 200
                        $P_cmb_NSG.Location = '200, 190'
                        

                        $P_lbl_Subnet.Width     = 150
                        $P_lbl_Subnet.Location  = '10, 220'
                        $P_lbl_Subnet.Text      = "Configured Subnets"

                        $p_lst_Subnet.Width     = 250
                        $p_lst_Subnet.Location  = '200, 220'
                        $p_lst_Subnet.Height      = '60'

                        $Popup.Size = '500, 400'
                        $p_Btn_Add.Location      = '200, 320'
                        $p_Btn_Add.Height        = 30

                        $Popup.Text = "Virtual Network"   

                        $p_Btn_Subnet_add.Location = '200,290'
                        $p_Btn_Subnet_add.Text = "+"

                        $p_Btn_Subnet_del.Location = '290,290'
                        $p_Btn_Subnet_del.Text = "-"

                        $Global:P_Subnets = @()
                        $p_Btn_Subnet_add.add_click({
                                                if ($P_txt_SubnetBlock.Text -match '\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/(\d){1,3}\b')
                                                {
                                                $Global:P_Subnets += [PSCUSTOMObject]@{Name = $P_txt_SubnetName.Text ;AddressPrefix = $P_txt_SubnetBlock.Text ; NetworkSecurityGroup = $P_cmb_NSG.SelectedItem}
                                                $p_lst_Subnet.Items.Add("$($P_txt_SubnetName.Text)  $($P_txt_SubnetBlock.Text) $($P_cmb_NSG.SelectedItem)")
                                                
                                                $p_i++
                                                $P_txt_SubnetName.Text      = "Subnet$($p_i)"
                                                $P_txt_SubnetBlock.Text      = "10.0.$($p_i).0/24"
                                                }
                                                Else
                                                {
                                                [System.Windows.Forms.MessageBox]::Show("The Subnet IP Range you enetered is not in a valid format.`n Example 10.0.1.0/24","Error",[System.Windows.Forms.MessageBoxButtons]::OK)
                                                }
                        
                        })

                         $p_Btn_Subnet_del.add_click({
                                                 $p_lst_Subnet.Items.Remove($p_lst_Subnet.SelectedItem)
                                                 $P_Subnets = @( $P_Subnets | ?{$_.Name -ne "$((($p_lst_Subnet.SelectedItem) -split " ")[0] )" })
                        
                         })

                       $P_cmb_NSG.add_SelectedValueChanged(
                        {

                                if ($P_cmb_NSG.SelectedItem -eq "New...")
                                {
                                Display-Form -Form 'NetworkSecurityGroup'
                                }

                        })

                       load-cmb -Data $h_RSGroups -Control $P_cmb_RSG  -Default $false
                       load-cmb -Data $h_NSG -Control $P_cmb_NSG  #-Default $false
                       
                        $p_Btn_Add.add_click({
                        
                                                IF ($P_txt_Address.Text -match '\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/(\d){1,3}\b')
                                                {
                                                                    $h_Networks."$($p_Txt_Name.Text)" = @{ResourceGroupName = $P_cmb_RSG.SelectedItem ; Location = $cmb_Location.SelectedItem ; Name = $p_Txt_Name.Text ; AddressSpace = $P_txt_Address.Text ; Subnets = $P_Subnets  ; Create = 1}
                                                                    load-cmb -Data $h_Networks -Control $cmb_Vnetwork
                                                                    $Popup.Close()
                                                }
                                                Else
                                                {
                                                [System.Windows.Forms.MessageBox]::Show("The Address block you enetered is not in a valid format.`n Example 10.0.0.0/16","Error",[System.Windows.Forms.MessageBoxButtons]::OK)
                                                }                
                                            
                                            })

        
        }
        'NetworkSecurityGroup' {
                        $P_Lbl_RSGName = New-Object System.Windows.Forms.Label
                        $P_cmb_RSG = New-Object System.Windows.Forms.ComboBox
                        $Popup.Size = '500, 250'
                        $P_Lbl_RSGName,$P_cmb_RSG |  %{$Popup.Controls.Add($_)}

                        $P_Lbl_RSGName.Width     = 150
                        $P_Lbl_RSGName.Location  = '10, 70'
                        $P_Lbl_RSGName.Text      = "ResourceGroup"
                        $P_cmb_RSG.Location      = '200, 70'
                        $P_cmb_RSG.Width         = '200'
                        $p_Btn_Add.Location      = '200, 100'

                        $Popup.Text = "Network Security Group"    
                        load-cmb -Data $h_RSGroups -Control $P_cmb_RSG  -Default $false
                        
                        
                        $p_Btn_Add.add_click({
                                           
                                            $h_NSG."$($p_Txt_Name.Text)" = @{Name = ($p_Txt_Name.Text).ToLower().Replace(" ",'') ;ResourceGroupName = $P_cmb_RSG.SelectedItem ; Location = $cmb_Location.SelectedItem ; Create = 1}
                                            load-cmb -Data $h_NSG -Control $P_cmb_NSG  

                                            $Popup.Close()
                                            })
                        
        
                        }
        'PublicIP' {
                        $P_Lbl_RSGName = New-Object System.Windows.Forms.Label
                        $P_cmb_RSG = New-Object System.Windows.Forms.ComboBox
                        $Popup.Size = '500, 250'
                        $P_Lbl_RSGName,$P_cmb_RSG |  %{$Popup.Controls.Add($_)}

                        $P_Lbl_RSGName.Width     = 150
                        $P_Lbl_RSGName.Location  = '10, 70'
                        $P_Lbl_RSGName.Text      = 'ResourceGroup'
                        $P_cmb_RSG.Location      = '200, 70'
                        $P_cmb_RSG.Width         = '200'
                        $p_Btn_Add.Location      = '200, 100'

                        $Popup.Text = 'PublicIP'   
                        load-cmb -Data $h_RSGroups -Control $P_cmb_RSG  -Default $false
                        
                        $p_Btn_Add.add_click({
                                           
                                            $h_Pip."$($p_Txt_Name.Text)" = @{Name = ($p_Txt_Name.Text) ;ResourceGroupName = $P_cmb_RSG.SelectedItem ; Location = $cmb_Location.SelectedItem ; Create = 1}
                                            load-cmb -Data $h_Pip -Control $cmb_PublicIP
                                            $Popup.Close()
                                            })
                        }
        'AVSet' {
                        $P_Lbl_RSGName = New-Object System.Windows.Forms.Label
                        $P_cmb_RSG = New-Object System.Windows.Forms.ComboBox
                        $P_Lbl_RSGName,$P_cmb_RSG |  %{$Popup.Controls.Add($_)}
                        $P_Lbl_RSGName.Width     = 150
                        $P_Lbl_RSGName.Location  = '10, 70'
                        $P_Lbl_RSGName.Text      = 'ResourceGroup'
                        $P_cmb_RSG.Location      = '200, 70'
                        $P_cmb_RSG.Width         = '200'
                        
                        load-cmb -Data $h_RSGroups -Control $P_cmb_RSG  -Default $false

                        $Popup.Size = '500, 200'
                        $p_Btn_Add.Location      = '200, 100'
                        $Popup.Text = "Availability Set"    
                        $p_Btn_Add.add_click({
                                            $h_AVS."$($p_Txt_Name.Text)" = @{Name = ($p_Txt_Name.Text) ;ResourceGroupName = $P_cmb_RSG.SelectedItem ; Location = $cmb_Location.SelectedItem ; Create = 1}
                                            load-cmb -Data $h_AVS -Control $cmb_Avset
                                            $Popup.Close()
                                            })
                        }

    }

$Popup.ShowDialog()

}

#endregion

Function load-SubscriptionData
{


Try{
        Write-Host 'Retrieving Azure Regions and Virtual Machine Size...' -ForegroundColor Green
        Get-AzureRMLocation | select DisplayName,@{N='VirtualMachineRoleSizes';E={(Get-AzureRmVMSize -Location $_.DisplayName).Name}} | %{$h_Location."$($_.DisplayName)" = $_.VirtualMachineRoleSizes} | Out-Null
        load-cmb -Data $h_Location -Control $cmb_Location | Out-Null
        #Write-Host "OK" -ForegroundColor Green 
} Catch {}

Try{
        Write-host 'Getting Storage Accounts...' -ForegroundColor Green 
        Get-AzureRmStorageAccount | Select-Object ResourceGroupName,Location,StorageAccountName  | `
        %{$h_Storage."$($_.StorageAccountName)" = @{ResourceGroupName = $_.ResourceGroupName ; Location = $_.Location ; StorageAccountName = $_.StorageAccountName} } | Out-Null
        load-cmb -Data $h_Storage -Control $cmb_Storage | Out-Null
        #Write-Host "OK" -ForegroundColor Green 
}
Catch{}


Try{
        Write-host 'Getting resource groups...' -ForegroundColor Green 
        Get-AzureRmResourceGroup | select ResourceGroupName,Location | %{$h_RSGroups."$($_.ResourceGroupName)" = @{ResourceGroupName = $_.ResourceGroupName ; Location = $_.Location} } | Out-Null
        load-cmb -Data $h_RSGroups -Control $cmb_RSG | Out-Null
        #Write-Host "OK" -ForegroundColor Green 
}
Catch{}

Try{
        Write-host 'Getting Network Security Groups...' -ForegroundColor Green 
        Get-AzureRmNetworkSecurityGroup | select ResourceGroupName,Location,Name | %{$h_NSG."$($_.Name)" = @{Name = $_.name; ResourceGroupName = $_.ResourceGroupName ; Location = $_.Location} } | Out-Null
        load-cmb -Data $h_NSG -Control $cmb_NSG | Out-Null
        #Write-Host "OK" -ForegroundColor Green 
}
Catch{}


Try{
        Write-host 'Getting Virtual Networks...' -ForegroundColor Green 

        Get-AzureRmVirtualNetwork |  select Subnets,AddressSpace,Name,ResourceGroupName,Location -PipelineVariable N| %{$h_Networks."$($_.Name)" = @{
        Name = $N.Name    
        AddressSpace = $N.AddressSpace.AddressPrefixes
        ResourceGroupName = $N.ResourceGroupName
        Subnets = $N.Subnets | %{ [PSCustomObject]@{Name=$_.name;AddressPrefix=$_.AddressPrefix;NetworkSecurityGroup=(($_.NetworkSecurityGroup.id) -split "/")[-1]}} 
        Location = $N.Location
        } 
        
        }

       # $h_Networks.Keys |%{ $h_Networks."$_".subnets }

        load-cmb -Data $h_Networks -Control $cmb_Vnetwork | Out-Null
        Write-Host 'OK' -ForegroundColor Green 
        Load-Subnet
       
}
Catch{}

Try{
        Write-host 'Getting PublicIp Instances...' -ForegroundColor Green 
        Get-AzureRmPublicIpAddress | ?{$_.IpAddress -eq 'Not Assigned'} |select ResourceGroupName,Location,Name | %{$h_Pip."$($_.Name)" = @{Name = $_.name; ResourceGroupName = $_.ResourceGroupName ; Location = $_.Location} } | Out-Null
        load-cmb -Data $h_Pip -Control $cmb_PublicIP | Out-Null
        #Write-Host "OK" -ForegroundColor Green 
}
Catch{}

#Load Initial AVset RSG required
load-cmb -Data $h_AVS -Control $cmb_AVSet | Out-Null

}

Try{
        Write-host 'Getting Azure Subscription...' -ForegroundColor Green 
        Get-AzureRmSubscription | % -Begin{$cmb_Subscription.Items.Clear()} -process{$cmb_Subscription.Items.Add($_.Name)}  |Out-Null
        $cmb_Subscription.SelectedIndex = 0
        load-SubscriptionData
        #Write-Host "OK" -ForegroundColor Green 
}
Catch{}

Function Check-RSG
{
Param($name)
        

        If ($h_RSGroups."$name".create -eq 1)
        {
        Write-Host "Resourcegroup $Name does not exist..." -ForegroundColor Cyan
            Try{
            $RSG  = New-AzureRmResourceGroup –Name $Name –Location "$($h_RSGroups."$name".location)" -ErrorAction Stop
            $h_RSGroups."$name".create = 0
            Write-Host "Created" -ForegroundColor Green 
            #return $RSG 
            }
            Catch{
            $_.Message
            Return
            }

        }

}

Function Check-Storage
{
param($StorageAccount)

                                    IF ($h_Storage."$StorageAccount".create -eq 1 )
                                    {
                                    Write-Host "Storageaccount $StorageAccount does not exist and will be created..." -ForegroundColor Cyan 
                                        Try{
                                                    
                                            New-AzureRmStorageAccount -ResourceGroupName "$($h_Storage."$StorageAccount".ResourceGroupName)" -Name $StorageAccount.ToLower() -Type Standard_LRS -Location "$($h_Storage."$StorageAccount".Location)" -Verbose | Out-Null
                                            $h_Storage."$StorageAccount".create = 0
                                            Write-Host "Completed" -ForegroundColor Green 
        
                                        }
                                        Catch{     $_.Message
                                        Return
                                        }
                                    }
                                    Else
                                    {
                                    $D_StorageAccount = Get-AzureRmStorageAccount -ResourceGroupName "$($h_Storage."$StorageAccount".ResourceGroupName)" -Name $StorageAccount

                                    }


}


Function Check-NSG
{
Param($NetworkSecurityGroup)

            IF ($h_NSG."$NetworkSecurityGroup".create -eq 1 )
            {
            Write-Host "Network Security Group $NetworkSecurityGroup does not exist and will be created..." -ForegroundColor Cyan 
                Try{
                 $D_nsg = New-AzureRmNetworkSecurityGroup -Name $NetworkSecurityGroup  -ResourceGroupName  "$($h_NSG."$NetworkSecurityGroup".ResourceGroupName)" -location "$($h_NSG."$NetworkSecurityGroup".Location)"
                 $h_NSG."$NetworkSecurityGroup".create = 0
                 Write-Host "Completed" -ForegroundColor Green 
                    } 
                    Catch {
                    $_.Message
                    }                                    
            }
}


Function Check-Network
{
Param($VirtualNetwork)
                            IF ($h_Networks."$VirtualNetwork".create -eq 1 )
                            {
                                    Write-Host "VirtualNetwork $VirtualNetwork does not exist and will be created..." -ForegroundColor Cyan
                                        Try{
                                            $subnets = @()
                                            

                                            try{

                                                $h_Networks.$VirtualNetwork.Subnets | %{if ($_.NetworkSecurityGroup -eq 'none')
                                                {$subnets += New-AzureRmVirtualNetworkSubnetConfig -Name $_.Name-AddressPrefix $_.AddressPrefix } 
                                                ELSE
                                                {$subnets += New-AzureRmVirtualNetworkSubnetConfig-Name $_.Name-AddressPrefix $_.AddressPrefix -NetworkSecurityGroup (Get-AzureRmNetworkSecurityGroup -Name $_.NetworkSecurityGroup -ResourceGroupName $h_NSG."$($_.NetworkSecurityGroup)".ResourceGroupName) }
                                                }
                                                }
                                            catch{
                                            $_.Message
                                            }
                                                   
                                        Try {
                                        $D_VirtualNetwork = New-AzureRmVirtualNetwork -Name "$($h_Networks."$VirtualNetwork".Name)"  -ResourceGroupName "$($h_Networks."$VirtualNetwork".ResourceGroupName)" -Location "$($h_Networks."$VirtualNetwork".Location)" -AddressPrefix "$($h_Networks."$VirtualNetwork".AddressSpace)" -Subnet $subnets
                                        $h_Networks."$VirtualNetwork".create = 0
                                        }
                                        Catch{
                                         $_.Message
                                        }
                                            Write-Host "Completed" -ForegroundColor Green 
             
                                        }
                                        Catch{     $_.Message
                                        Return
                                        }
                                    }


}


Function Check-AVset
{
Param($Avset)
        

        If ($h_AVS."$Avset".create -eq 1)
        {
        Write-Host "Availability Set $AVset does not exist..." -ForegroundColor Cyan
            Try{
            New-AzureRmAvailabilitySet –Name $Avset -ResourceGroupName $h_AVS."$avset".ResourceGroupName  –Location "$($h_AVS."$Avset".location)" -ErrorAction Stop
            $h_Avs."$Avset".create = 0
            Write-Host "Created $AVset" -ForegroundColor Green 
            #return $RSG 
            }
            Catch{
            $_.Message
            Return
            }

        }

}


function Check-Publicnic
{Param($PIPname)
        if ($h_Pip."$($cmb_PublicIP.SelectedItem)".create -eq 1)
        {
        Write-Host "Create a new instance level public IP address..." -ForegroundColor cyan 
        $pip = New-AzureRmPublicIpAddress -ResourceGroupName $h_Pip."$($cmb_PublicIP.SelectedItem)".ResourceGroupName -Name $h_Pip."$($cmb_PublicIP.SelectedItem)".name -Location $h_Pip."$($cmb_PublicIP.SelectedItem)".location -AllocationMethod Dynamic
        $h_Pip."$($cmb_PublicIP.SelectedItem)".create = 0
        Write-Host "Completed" -ForegroundColor Green 
        }

}


function load-grid
{
$Grid_VMs.rows.Clear()
$Grid_VMs.Columns.Clear()
#$Global:VMs | %{$Grid_VMs.Rows.ad}
'Location','ResourceGroupName','StorageAccount','VirtualNetwork','Subnet','NetworkSecurityGroup','PublicIp','VMSize','VMName','DiskName','PublisherName','Offer','Skus','Version' | %{$Grid_VMs.columns.Add($_,$_)} | Out-Null

$Global:VMs | %{
$Grid_VMs.Rows.Add(
"$($_.Location)", "$($_.ResourceGroupName)", "$($_.StorageAccount)", "$($_.VirtualNetwork)", "$($_.Subnet)", "$($_.NetworkSecurityGroup)", "$($_.PublicIp)", "$($_.VMSize)", "$($_.VMName)", "$($_.DiskName)", "$($_.PublisherName)", "$($_.Offer)", "$($_.Skus)", "$($_.Version)"
)}

}



#region c_location

#$Gb_RSG.Location= '590,20'
$cmb_RSG.Location              = '10, 400'

$label_Subscription.Location            = '10, 30'
$label_Location.Location       = '10, 60'
$label_Rsg.Location            = '10, 90'
$label_StorageAccount.Location = '10, 120'
$label_VnetWork.Location       = '10, 150'
$label_Subnet.Location         = '10, 180'     
$label_Avset.Location          = '10, 210'
$label_PiP.Location            = '10, 240'
$label_VMSize.Location         = '10, 270'
$label_VMname.Location         = '10, 300'
$label_VMpulisher.Location     = '10, 330'
$label_VMImageOffer.Location   = '10, 360'
$label_VMImageSku.Location     = '10, 390'
$label_VMVersion.location      = '10, 420'

$Grid_VMs.Location             = '10, 510'
$Grid_VMs.Width                = '450'

$cmb_Subscription.Location     = '200, 30'
$cmb_Location.Location         = '200, 60'
$cmb_RSG.Location              = '200, 90'
$cmb_Storage.Location          = '200, 120'
$cmb_Vnetwork.Location         = '200, 150'
$cmb_Subnet.Location           = '200, 180' 
$cmb_AVSet.Location            = '200, 210'    
$label_PiPC.Location           = '200, 240'
$cmb_PublicIP.Location         = '230, 240'
$cmb_VMSize.Location           = '200, 270'
$txt_VMName.Location           = '200, 300'
$cmb_VMpublisher.Location      = '200, 330'
$cmb_VMImageOffer.Location     = '200, 360'
$cmb_VMImageSku.Location       = '200, 390'
$cmb_VMVersion.Location        = '200, 420'


$cmb_Subscription.TabIndex     = '100'
$cmb_Location.TabIndex         = '101'
$cmb_RSG.TabIndex              = '102'
$cmb_Storage.TabIndex          = '103'
$cmb_Vnetwork.TabIndex         = '104'
$cmb_Subnet.TabIndex           = '105' 
$cmb_AVSet.TabIndex            = '106'    
$label_PiPC.TabIndex           = '107'
$cmb_PublicIP.TabIndex         = '108'
$cmb_VMSize.TabIndex           = '109'
$txt_VMName.TabIndex           = '110'
$cmb_VMpublisher.TabIndex      = '111'
$cmb_VMImageOffer.TabIndex     = '112'
$cmb_VMImageSku.TabIndex       = '113'
$cmb_VMVersion.TabIndex        = '114'



$btn_AddConfig.Location        = '200, 480'
$btn_Deploy_VM.Location        = '320, 480'
$btn_Credentials.Location      = '200, 450'
#endregion

#region Sizing
$Form.Height = 800
$Form.Width = 1024

$label_Location.width       = '150'
$label_Rsg.width            = '150'
$label_StorageAccount.width = '150'
$label_VnetWork.width       = '150'
$label_Subnet.width         = '150'
$label_PiP.width            = '150'
$label_VMSize.width         = '150'
$label_VMname.Width         = '150'
$label_VMpulisher.Width     = '150'
$label_VMImageOffer.Width   = '150'
$label_VMImageSku.Width     = '150'
$label_VMVersion.Width      = '150'
$label_PiPC.Width           = '25'

$cmb_Subscription.Width     = '250'
$cmb_RSG.width              = '250'
$cmb_Location.width         = '250'
$cmb_Storage.width          = '250'
$cmb_Vnetwork.width         = '250'
$cmb_Subnet.width           = '250'
$cmb_AVSet.Width            = '250'
$cmb_RSG.width              = '250'
$cmb_VMSize.Width           = '250'
$txt_VMName.Width           = '250'
$cmb_VMpublisher.Width      = '250'
$cmb_VMImageOffer.Width     = '250'
$cmb_VMImageSku.Width       = '250'
$cmb_VMVersion.Width        = '250'
$cmb_PublicIP.Width         = '220'

$cmb_PublicIP.Visible       = $false
$btn_AddConfig.Width        = '100'
$btn_Deploy_VM.Width        = '130'
$btn_Credentials.Width      = '250'
#endregion

#region TextPoperties
$label_Subscription.Text = "Subscription"
$label_Rsg.Text       = "Resource Group"
$label_Location.Text        = 'Location'
$label_StorageAccount.Text  = "Storage Account"
$label_VnetWork.Text = "Virtual Network"
$label_Subnet.Text   = 'Subnet'
$label_Avset.Text    = 'Availability Set'
$label_PiP.Text = "Public Ip Address"
$label_VMSize.text = "VM Size"
$label_VMname.Text = "VM Name"
$label_VMpulisher.Text = "Image Publisher"
$label_VMImageOffer.Text = "Image Offer"
$label_VMImageSku.Text = "Image SKU"
$label_VMVersion.Text = "Image Version"
$btn_AddConfig.Text   = "Add VM"
$btn_Deploy_VM.Text   = "Deploy to Azure"
$btn_Credentials.Text = "Set Local Admin Credentials"
#endregion

#region formconstruction

$label_Avset,$cmb_AVSet ,$label_Location,$label_Rsg,$label_StorageAccount,$label_VnetWork,$label_Subnet,$label_PiP,$label_PiPC,$label_VMSize,$cmb_VMSize,$label_VMname,$txt_VMName,$cmb_VMpublisher,$label_VMpulisher,$label_VMImageSku,$cmb_VMImageSku,$cmb_VMVersion,$label_VMVersion,$cmb_VMImageOffer,$label_VMImageOffer,$btn_AddConfig,`
$btn_Credentials,$cmb_PublicIP,$label_Subscription,$cmb_Subscription,$Grid_VMs,$cmb_Location,$cmb_Storage,$cmb_Vnetwork,$cmb_Subnet,$cmb_RSG,$btn_Deploy_VM|`
 %{$Form.Controls.Add($_)} | Out-Null

$btn_Credentials.add_click({
            $Global:Cred = Get-Credential -Message "Please provide the Local Admin credentials to deploy, must be atleast 12 Characters."
            if ($Global:Cred -ne '' -and $Global:cred.GetNetworkCredential().password.length -gt '11')
            {
            
            $btn_Credentials.Text = "Credentials Set:$($cred.UserName)"
            $btn_Deploy_VM.Enabled = $true
            }
            ELSE
            {
            
            
            }
           # $Form.Show()

})

$cmb_Location.add_SelectedValueChanged(
{
$h_Location."$($cmb_Location.SelectedItem)" | ForEach-Object -Begin {$cmb_VMSize.Items.Clear() } -Process {$cmb_VMSize.Items.Add($_)}

Try {Get-AzureRmVMImagePublisher –Location "$($cmb_Location.SelectedItem)"  | % -Begin {$cmb_VMpublisher.Items.Clear()} -Process {$cmb_VMpublisher.Items.Add($_.PublisherName)}
}
Catch
{}

})


$cmb_Storage.add_SelectedValueChanged(
{
        if ($cmb_Storage.SelectedItem -eq "New...")
        {
        Display-Form -Form 'StorageAccount'
        }
})

$cmb_RSG.add_SelectedValueChanged(
{

        if ($cmb_RSG.SelectedItem -eq "New...")
        {
        Display-Form -Form 'ResourceGroup'
        }
        Try{
        #Write-host 'Getting Availability Set ...' -ForegroundColor Green 
        Get-AzureRmAvailabilitySet -ResourceGroupName $cmb_RSG.SelectedItem -ErrorAction SilentlyContinue| select ResourceGroupName,Location,Name | %{$h_AVS."$($_.Name)" = @{Name = $_.name; ResourceGroupName = $_.ResourceGroupName ; Location = $_.Location} } | Out-Null
        load-cmb -Data $h_AVS -Control $cmb_Avset | Out-Null
        #Write-Host "OK" -ForegroundColor Green 
}
Catch{}

})

$cmb_Vnetwork.add_SelectedValueChanged({

        if ($cmb_Vnetwork.SelectedItem -eq "New...")
        {
        Display-Form -Form "VirtualNetwork"
        }
        Else
        {
        Load-Subnet -Network "$($cmb_Vnetwork.SelectedItem)"
        }
#Load-Subnet 
})


$cmb_Avset.add_SelectedValueChanged(
{
        if ($cmb_AVset.SelectedItem -eq "New...")
        {
        Display-Form -Form "AVSet"
        }
        

}
)


$cmb_PublicIP.add_SelectedValueChanged(
{

        if ($cmb_PublicIP.SelectedItem -eq "New...")
        {
        Display-Form -Form 'PublicIP'
        }

})


$cmb_VMpublisher.add_SelectedValueChanged({
Get-AzureRmVMImageOffer –Location "$($cmb_Location.SelectedItem)"  -PublisherName "$($cmb_VMpublisher.SelectedItem)" |% -Begin{$cmb_VMImageOffer.Items.Clear() } -Process {$cmb_VMImageOffer.Items.Add($_.Offer)}

})

$label_PiPC.add_CheckedChanged({
if ($label_PiPC.Checked)
    {$cmb_PublicIP.Visible = $true
}
Else
    {$cmb_PublicIP.Visible = $false}

})

$cmb_Subscription.add_SelectedValueChanged({
if ($cmb_Subscription.Items.Count -gt 1)
{
Select-AzureRmSubscription -SubscriptionName $cmb_Subscription.SelectedItem
load-SubscriptionData

}
})

$cmb_VMImageOffer.add_SelectedValueChanged({
Get-AzureRmVMImageSku –Location "$($cmb_Location.SelectedItem)" –PublisherName "$($cmb_VMpublisher.SelectedItem)" –Offer "$($cmb_VMImageOffer.SelectedItem)" | % -Begin{$cmb_VMImageSku.Items.Clear()} -Process {$cmb_VMImageSku.Items.Add($_.Skus) }
})

$cmb_VMImageSku.add_SelectedValueChanged({
#

Get-AzureRmVMImage –Location "$($cmb_Location.SelectedItem)" –Offer "$($cmb_VMImageOffer.SelectedItem)" –PublisherName "$($cmb_VMpublisher.SelectedItem)" -Skus "$($cmb_VMImageSku.SelectedItem)" | % -Begin{$cmb_VMVersion.Items.Clear()} -Process{$cmb_VMVersion.Items.add($_.Version)}
})

Function Validate-Object
{
Param($Data)


        Switch ($Data)
        {
        {$Data -eq ''}{Return $false}
        {$Data -eq 'new...'}{Return $false}
        {$Data -eq $null}{Return $false}
        Default {Return $True}
        }

}




$btn_AddConfig.add_click({
$result = @()
 $Validate = @($cmb_Location.SelectedItem,$cmb_RSG.SelectedItem,$cmb_Storage.SelectedItem,$cmb_Vnetwork.SelectedItem,$cmb_Subnet.SelectedItem,$cmb_VMSize.SelectedItem,$txt_VMName.Text,$cmb_VMpublisher.SelectedItem, $cmb_VMImageOffer.SelectedItem,$cmb_VMImageSku.SelectedItem,$cmb_VMVersion.SelectedItem,$cmb_AVSet.SelectedItem)
 $Validate | %{$result += Validate-Object -Data $_}

 if (!($result -contains $false))
 {

        $obj = [PSCustomObject]@{
        Location             = $cmb_Location.SelectedItem
        ResourceGroupName    = $cmb_RSG.SelectedItem
        StorageAccount       = @{Name="$($cmb_Storage.SelectedItem)"; ResourceGroup= $h_Storage."$($cmb_Storage.SelectedItem)".ResourceGroupName}
        VirtualNetwork       = $h_Networks."$($cmb_Vnetwork.SelectedItem)"
        Subnet               = "$($cmb_Subnet.SelectedItem)".Split('')[0]
        AVSet                = $h_AVS."$($cmb_AVSet.SelectedItem)"
        NetworkSecurityGroup = "$(($cmb_Subnet.SelectedItem).Split('')[-1])"
        PublicIp             = ($label_PiPC.Checked)
        VMSize               = $cmb_VMSize.SelectedItem
        VMName               = $txt_VMName.Text
        DiskName             = "$($txt_VMName.Text)-01"
        PublisherName        = $cmb_VMpublisher.SelectedItem
        Offer                = $cmb_VMImageOffer.SelectedItem
        Skus                 = $cmb_VMImageSku.SelectedItem
        Version              = $cmb_VMVersion.SelectedItem
        VhdUri               = ''
        NicID                = ''
        PuplicIPName         = @{name='';ResourceGroup=''}
        Credentials          = $Cred
        }


        if (($label_PiPC.Checked -eq $true) -and ($cmb_PublicIP.SelectedItem -ne "New..."))
        {
        $obj.PuplicIPName = $h_Pip."$($cmb_PublicIP.SelectedItem)"
        }

        $Global:VMs += $obj

        load-grid
        }
        else
        {
        [System.Windows.Forms.MessageBox]::Show("Please Complete all Fields, make sure no selection is set to 'New...'","Error",[System.Windows.Forms.MessageBoxButtons]::OK)
        }
})

$btn_Deploy_VM.add_Click({



#Create resources for new VM's
$h_RSGroups.Keys | ?{$_ -ne "new..."} | %{Check-RSG -name $_}
$h_Storage.Keys | ?{$_ -ne "new..."} | %{Check-Storage -StorageAccount $_}
$h_NSG.Keys| ?{$_ -ne "new..."} | %{Check-NSG -NetworkSecurityGroup $_}
$h_Pip.Keys| ?{$_ -ne "new..."} | %{Check-Publicnic -PIPname $_}
$h_Networks.Keys| ?{$_ -ne "new..."} | %{Check-Network -VirtualNetwork $_}
$h_AVS.Keys | ?{$_ -ne "new..." -and $_ -ne 'None'} | %{Check-AVset -Avset $_}
 
Workflow Deploy-all
{
Param($data,$Azurecred)


foreach -parallel ($vm in $data)
{
InlineScript { 

               #New Contect -need to login again
                Add-AzureRmAccount -Credential $using:Azurecred -ErrorAction Stop
              
                $Location = $using:vm.location
                $ResourceGroupName = $using:vm.ResourceGroupName
                $StorageAccount = Get-AzureRmStorageAccount -Name $using:vm.StorageAccount.name -ResourceGroupName $using:vm.StorageAccount.ResourceGroup
                $VirtualNetwork = Get-AzureRmVirtualNetwork -Name $using:vm.VirtualNetwork.Name -ResourceGroupName $using:vm.VirtualNetwork.ResourceGroupName
                $Subnet = $using:vm.Subnet
                $NetworkSecurityGroup = $using:vm.NetworkSecurityGroup
                $PublicIp = $using:vm.PublicIp
                $VMSize = $using:vm.VMSize
                $VMName = $using:vm.VMName
                $DiskName = "$($VMName)-$([string](get-date -Format ddMMyyyy))-OS"
                $PublisherName = $using:vm.PublisherName
                $Offer = $using:vm.offer
                $Skus = $using:vm.Skus
                $Version = $using:vm.Version
                $VhdUri = $StorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $DiskName + ".vhd"  
                $PublicIpName = $using:vm.PuplicIPName
                $Credentials = $using:vm.Credentials
                $AV_Set = $using:vm.AVSet.Name
                #Write-Host "AV Set $AV_Set"
                
                Write-host "$(get-date) `t $VMName Task started" -ForegroundColor Cyan        
               
                #create a new virtual machine Config
                if ($AV_Set -eq '' -or $AV_Set -eq 'None' -or $AV_Set -eq $null)
                {
                #No AV Set
                $D_vmConfig = New-AzureRmVMConfig –VMName $VMName -VMSize $VMSize 
                
                }
                Else
                {
                #AVSet
                $AVID =  Get-AzureRmAvailabilitySet -Name $AV_Set -ResourceGroupName $ResourceGroupName
                
                
                $D_vmConfig = New-AzureRmVMConfig –VMName $VMName -VMSize $VMSize -AvailabilitySetId $AVID.ID -Verbose
                }
                #write-host "Get-AzureRmAvailabilitySet -Name $AV_Set -ResourceGroupName $ResourceGroupName `n New-AzureRmVMConfig –VMName $VMName -VMSize $VMSize -AvailabilitySetId $($AVID.ID) "

                
                
                $D_vmConfig | Set-AzureRmVMOperatingSystem -Windows -ComputerName $VMName -Credential $Credentials -ProvisionVMAgent -EnableAutoUpdate
                $D_vmConfig | Set-AzureRmVMSourceImage -PublisherName $PublisherName -Offer $Offer -Skus $Skus -Version $Version  
 
                 IF ($PublicIp -eq 'True')
                {
                $pip = Get-AzureRmPublicIpAddress -ResourceGroupName $PublicIpName.ResourceGroupName -Name $PublicIpName.name
 
                Write-Host "$(get-date) `t Create a new Private Nic for $VMName..." -ForegroundColor Green 
                $d_Subnet = Get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $VirtualNetwork |?{$_.Name -eq "$(($Subnet -split " ")[0])" }

                $Nic = New-AzureRmNetworkInterface -ResourceGroupName $resourceGroupName -Name "$VMName-nic".ToLower() -Subnet $d_Subnet  -PublicIpAddress $pip  -Location $Location
                 
                }
                Else
                {
                $d_Subnet = Get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $VirtualNetwork |?{$_.Name -eq "$(($Subnet -split " ")[0])" }

                 Write-Host "$(get-date) `t Create a new Private Nic for $VMName..." -ForegroundColor Green 
                 $Nic = New-AzureRmNetworkInterface -ResourceGroupName $resourceGroupName -Name "$VMName-nic".ToLower() -Subnet $d_Subnet -Location $location 
                
                }

 

                $D_vmConfig | Set-AzureRmVMOSDisk -Name "$($VMName)-D1" -Caching ReadWrite -CreateOption fromImage  -VhdUri $VhdUri
                $D_vmConfig | Add-AzureRmVMNetworkInterface -Id $nic.Id

                New-AzureRmVM -ResourceGroupName $resourceGroupName -Location $location -VM $D_vmConfig 
                
                Write-host "$(get-date) `t $VMName Deployment Completed" -ForegroundColor Cyan  

             } 
}

}

Deploy-all -data $Global:VMs -Azurecred $AutoCred


Write-Host "All Deployments Done!" -ForegroundColor Green

$Form.Refresh()

})


$Form.ShowDialog()
#$Form.Show()

#endregion