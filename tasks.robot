*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${False}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Windows
Library             RPA.RobotLogListener
Library             RPA.Archive
Library             RPA.FileSystem


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Clean out Folder
    Open the robot order website
    Download Orders
    ${orders_for_entry}=
    ...    Extract orders from CSV
    FOR    ${order}    IN    @{orders_for_entry}
        Close the prompt
        Fill the form for one order    ${order}
        Wait Until Keyword Succeeds    5x    2s    Preview robot order
        Wait Until Keyword Succeeds    5x    2s    Submit robot order
        ${screenshot_file}=    Take a mugshot of the robot    ${order}[Order number]
        ${receipt_file}=    Store receipt in a PDF    ${order}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot_file}    ${receipt_file}
        Order another robot
    END
    Create zip file of finalaized receipts
    [Teardown]    Close Windows


*** Keywords ***
Open the robot order website
    Open Available Browser
    ...    https://robotsparebinindustries.com/#/robot-order
    ...    maximized=${True}

Close the prompt
    Wait Until Page Contains Element
    ...    class:modal-header
    Click Button
    ...    OK
    Wait Until Page Contains Element    class:form-group

Download Orders
    Download
    ...    https://robotsparebinindustries.com/orders.csv
    ...    %{ROBOT_ROOT}${/}Orders.csv
    ...    overwrite=${True}

Extract orders from CSV
    ${orders}=
    ...    Read table from CSV
    ...    %{ROBOT_ROOT}${/}Orders.csv
    ...    header=${True}
    RETURN
    ...    ${orders}

Fill the form for one order
    [Arguments]    ${order}
    Select From List By Index
    ...    id=head
    ...    ${order}[Head]
    Click Element
    ...    id=id-body-${order}[Body]
    Input Text
    ...    alias:Legs
    ...    ${order}[Legs]
    Input Text
    ...    id=address
    ...    ${order}[Address]

Preview robot order
    Click Button
    ...    id=preview
    Wait Until Page Contains Element
    ...    id=robot-preview-image

Submit robot order
    Mute Run On Failure
    ...    Page should Contain Element
    Click Button
    ...    id=order
    Page Should Contain Element
    ...    id=receipt

Order another robot
    Click Button
    ...    id=order-another

Store receipt in a PDF
    [Arguments]
    ...    ${order_number}

    Set Local Variable
    ...    ${order_receipt_file}
    ...    ${OUTPUT_DIR}${/}Robot Receipts/Receipt_For_Order_${order_number}.pdf
    Wait Until Page Contains Element
    ...    id=receipt
    ${receipt_html}=
    ...    Get Element Attribute
    ...    id=receipt
    ...    outerHTML
    Html To Pdf
    ...    ${receipt_html}
    ...    ${order_receipt_file}
    RETURN
    ...    ${order_receipt_file}

Take a mugshot of the robot
    [Arguments]
    ...    ${order_number}

    Set Local Variable
    ...    ${robot_mugshot_file}
    ...    ${OUTPUT_DIR}${/}Robot Screenshots/Order_${order_number}.png
    Wait Until Page Contains Element
    ...    id=robot-preview-image
    Capture Element Screenshot
    ...    id=robot-preview-image
    ...    ${robot_mugshot_file}
    RETURN
    ...    ${robot_mugshot_file}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}

    @{files_for_pdf}=
    ...    Create List
    ...    ${screenshot}
    Open Pdf
    ...    ${pdf}
    Add Files To Pdf
    ...    ${files_for_pdf}
    ...    ${pdf}
    ...    ${True}
    #Close Pdf
    #...    ${pdf}

Create zip file of finalaized receipts
    Archive Folder With Zip
    ...    ${OUTPUT_DIR}${/}Robot Receipts
    ...    ${OUTPUT_DIR}${/}reciepts.zip

Close Windows
    Close Browser

Clean out Folder
    Empty Directory
    ...    ${OUTPUT_DIR}${/}Robot Receipts
    Empty Directory
    ...    ${OUTPUT_DIR}${/}Robot Screenshots
