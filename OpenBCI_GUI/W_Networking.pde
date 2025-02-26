///////////////////////////////////////////////////////////////////////////////
//
//    W_Networking.pde (Networking Widget)
//
//    This widget provides networking capabilities in the OpenBCI GUI.
//    The networking protocols can be used for outputting data
//    from the OpenBCI GUI to any program that can receive UDP, OSC,
//    or LSL input, such as Matlab, MaxMSP, Python, C/C++, etc.
//
//    The protocols included are: UDP, OSC, and LSL.
//
//
//    Created by: Gabriel Ibagon (github.com/gabrielibagon), January 2017
//
///////////////////////////////////////////////////////////////////////////////


class W_Networking extends Widget {

    /* Variables for protocol selection */
    int protocolIndex;
    String protocolMode;

    /* Widget CP5 */
    ControlP5 cp5_networking;
    ControlP5 cp5_networking_dropdowns;
    ControlP5 cp5_networking_baudRate;
    ControlP5 cp5_networking_portName;

    boolean dataDropdownsShouldBeClosed = false;
    // CColor dropdownColors_networking = new CColor();

    // PApplet ourApplet;

    /* UI Organization */
    /* Widget grid */
    int column0;
    int column1;
    int column2;
    int column3;
    int column4;
    int fullColumnWidth;
    int halfWidth;
    int row0;
    int row1;
    int row2;
    int row3;
    int row4;
    int row5;
    int itemWidth = 96;
    private final float datatypeDropdownScaling = .35;

    /* UI */
    Boolean osc_visible;
    Boolean udp_visible;
    Boolean lsl_visible;
    Boolean serial_visible;
    List<String> dataTypes;
    Button startButton;
    Boolean cp5ElementsAreActive = false;
    Boolean previousCP5State = false;
    Button guideButton;

    /* Networking */
    Boolean networkActive;

    /* Streams Objects */
    Stream stream1;
    Stream stream2;
    Stream stream3;
    Stream stream4;

    List<String> baudRates;
    List<String> comPorts;
    private int comPortToSave;
    String defaultBaud;
    String[] datatypeNames = {"dataType1","dataType2","dataType3","dataType4"};
    String[] oscTextFieldNames = {
        "OSC_ip1","OSC_port1","OSC_address1",
        "OSC_ip2","OSC_port2","OSC_address2",
        "OSC_ip3","OSC_port3","OSC_address3",
        "OSC_ip4","OSC_port4","OSC_address4"};
    String[] oscTextDefaultVals = {
        "127.0.0.1","12345","/openbci",
        "127.0.0.1","12346","/openbci",
        "127.0.0.1","12347","/openbci",
        "127.0.0.1","12348","/openbci"};
    String[] udpTextFieldNames = {
        "UDP_ip1","UDP_port1",
        "UDP_ip2","UDP_port2",
        "UDP_ip3","UDP_port3"};
    String[] udpTextDefaultVals = {
        "127.0.0.1","12345",
        "127.0.0.1","12346",
        "127.0.0.1","12347",
        "127.0.0.1","12348"};
    String[] lslTextFieldNames = {
        "LSL_name1","LSL_type1","LSL_numchan1",
        "LSL_name2","LSL_type2","LSL_numchan2",
        "LSL_name3","LSL_type3","LSL_numchan3"};
    String[] lslTextDefaultVals = {
        "obci_eeg1","EEG",Integer.toString(nchan),
        "obci_eeg2","EEG",Integer.toString(nchan),
        "obci_eeg3","EEG",Integer.toString(nchan)};
    String networkingGuideURL = "https://openbci.github.io/Documentation/docs/06Software/01-OpenBCISoftware/GUIWidgets#networking";
    boolean configIsVisible = false;
    boolean layoutIsVisible = false;

    HashMap<String, Object> cp5Map = new HashMap<String, Object>();

    W_Networking(PApplet _parent) {
        super(_parent);
        // ourApplet = _parent;

        networkActive = false;
        stream1 = null;
        stream2 = null;
        stream3 = null;
        stream4 = null;

        //default data types for streams 1-4 in Networking widget
        settings.nwDataType1 = 0;
        settings.nwDataType2 = 0;
        settings.nwDataType3 = 0;
        settings.nwDataType4 = 0;
        settings.nwSerialPort = "None";
        settings.nwProtocolSave = protocolIndex; //save default protocol index, or 0, updates in the Protocol() function
        
        dataTypes = new LinkedList<String>(Arrays.asList(settings.nwDataTypesArray)); //Add any new widgets capable of streaming here
        //Only show pulse data type when using Cyton in Live
        if (eegDataSource != DATASOURCE_CYTON) {
            dataTypes.remove("Pulse");
        }
        defaultBaud = "115200";
        baudRates = Arrays.asList(settings.nwBaudRatesArray);
        protocolMode = "Serial"; //default to Serial
        addDropdown("Protocol", "Protocol", Arrays.asList(settings.nwProtocolArray), protocolIndex);
        comPorts = new ArrayList<String>(Arrays.asList(Serial.list()));
        verbosePrint("comPorts = " + comPorts);
        comPortToSave = 0;


        initialize_UI();
        cp5_networking.setAutoDraw(false);
        cp5_networking_dropdowns.setAutoDraw(false);
        cp5_networking_portName.setAutoDraw(false);
        cp5_networking_baudRate.setAutoDraw(false);

        fetchCP5Data();
    }

    //Used to update the Hashmap
    public void fetchCP5Data() {
        for (int i = 0; i < datatypeNames.length; i++) {
            //datatypes
            cp5Map.put(datatypeNames[i], int(cp5_networking_dropdowns.get(ScrollableList.class, datatypeNames[i]).getValue()));
            //filter radio buttons
            String filterName = "filter" + (i+1);
            cp5Map.put(filterName, int(cp5_networking.get(RadioButton.class, filterName).getValue()));
        }
        //osc textfields
        copyCP5TextToMap(oscTextFieldNames, cp5Map);
        //udp textfields
        copyCP5TextToMap(udpTextFieldNames, cp5Map);
        //lsl textfields
        copyCP5TextToMap(lslTextFieldNames, cp5Map);
        //Serial baud rate and port name
        cp5Map.put("baud_rate", int(cp5_networking_baudRate.get(ScrollableList.class, "baud_rate").getValue()));
        String s = cp5_networking_portName.get(ScrollableList.class, "port_name").getItem(comPortToSave).get("name").toString();
        cp5Map.put("port_name", s);
        //println(cp5Map);
    }

    private void copyCP5TextToMap(String[] keys, HashMap m) {
        for (int i = 0; i < keys.length; i++) {
            m.put(keys[i], cp5_networking.get(Textfield.class, keys[i]).getText());
        }
    }

    public Map getCP5Map() {
        return cp5Map;
    }

    /* ----- USER INTERFACE ----- */

    void update() {
        super.update();
        if (protocolMode.equals("LSL")) {
            if (stream1!=null) {
                stream1.run();
            }
            if (stream2!=null) {
                stream2.run();
            }
            if (stream3!=null) {
                stream3.run();
            }
            //Setting this var here fixes #592 to allow multiple LSL streams
            dataProcessing.newDataToSend = false;
        }

        checkTopNovEvents();

        //ignore top left button interaction when widgetSelector dropdown is active
        ignoreButtonCheck(guideButton);

        if (dataDropdownsShouldBeClosed) { //this if takes care of the scenario where you select the same widget that is active...
            dataDropdownsShouldBeClosed = false;
        } else {
            openCloseDropdowns();
        }

        if (protocolMode.equals("OSC")) {
            cp5ElementsAreActive = textfieldsAreActive(oscTextFieldNames);
        } else if (protocolMode.equals("UDP")) {
            cp5ElementsAreActive = textfieldsAreActive(udpTextFieldNames);
        } else if (protocolMode.equals("LSL")) {
            cp5ElementsAreActive = textfieldsAreActive(lslTextFieldNames);
        } else {
            //For serial mode, disable fft output by switching to bandpower instead
            this.disableCertainOutputs((int)getCP5Map().get(datatypeNames[0]));
        }

        if (cp5ElementsAreActive != previousCP5State) {
            if (!cp5ElementsAreActive) {
                //Cp5 textfield elements state change from 1 to 0, so save cp5 data
                fetchCP5Data();
            }
            previousCP5State = cp5ElementsAreActive;
        }


    } //end update()

    Boolean textfieldsAreActive(String[] names) {
        boolean isActive = false;
        for (String name : names) {
            if (cp5_networking.get(Textfield.class, name).isFocus()) {
                isActive = true;
            }
        }
        return isActive;
    }

    void draw() {
        super.draw();
        pushStyle();

        showCP5();

        cp5_networking.draw();

        //draw dropdown strokes
        pushStyle();
        fill(255);
        if (!protocolMode.equals("Serial")) {
            for (int i = 0; i < datatypeNames.length; i++) {
                rect(cp5_networking_dropdowns.getController(datatypeNames[i]).getPosition()[0] - 1, cp5_networking_dropdowns.getController(datatypeNames[i]).getPosition()[1] - 1, itemWidth + 2, cp5_networking_dropdowns.getController(datatypeNames[i]).getHeight()+2);
            }
        } else {
            rect(cp5_networking_portName.getController("port_name").getPosition()[0] - 1, cp5_networking_portName.getController("port_name").getPosition()[1] - 1, cp5_networking_portName.getController("port_name").getWidth() + 2, cp5_networking_portName.getController("port_name").getHeight()+2);
            cp5_networking_portName.draw();
            rect(cp5_networking_baudRate.getController("baud_rate").getPosition()[0] - 1, cp5_networking_baudRate.getController("baud_rate").getPosition()[1] - 1, cp5_networking_baudRate.getController("baud_rate").getWidth() + 2, cp5_networking_baudRate.getController("baud_rate").getHeight()+2);
            cp5_networking_baudRate.draw();
            rect(cp5_networking_dropdowns.getController("dataType1").getPosition()[0] - 1, cp5_networking_dropdowns.getController("dataType1").getPosition()[1] - 1, cp5_networking_dropdowns.getController("dataType1").getWidth() + 2, cp5_networking_dropdowns.getController("dataType1").getHeight()+2);
        }
        cp5_networking_dropdowns.draw();
        popStyle();

        // cp5_networking_dropdowns.draw();
        int headerFontSize = 18;
        fill(0,0,0);// Background fill: white
        textFont(h1, headerFontSize);

        if (!protocolMode.equals("Serial")) {
            text(" Stream 1",column1,row0);
            text(" Stream 2",column2,row0);
            text(" Stream 3",column3,row0);
        }
        if (protocolMode.equals("OSC")) {
            text(" Stream 4",column4,row0);
        }
        text("Data Type",column0,row1);

        startButton.draw();
        guideButton.draw();

        if (protocolMode.equals("OSC")) {
            textFont(f4,40);
            text("OSC", x+20,y+h/8+15);
            textFont(h1,headerFontSize);
            text("IP", column0,row2);
            text("Port", column0,row3);
            text("Address",column0,row4);
            text("Filters",column0,row5);
        } else if (protocolMode.equals("UDP")) {
            textFont(f4,40);
            text("UDP", x+20,y+h/8+15);
            textFont(h1,headerFontSize);
            text("IP", column0,row2);
            text("Port", column0,row3);
            text("Filters",column0,row4);
        } else if (protocolMode.equals("LSL")) {
            textFont(f4,40);
            text("LSL", x+20,y+h/8+15);
            textFont(h1,headerFontSize);
            text("Name", column0,row2);
            text("Type", column0,row3);
            text("# Chan", column0, row4);
        } else if (protocolMode.equals("Serial")) {
            textFont(f4,40);
            text("Serial", x+20,y+h/8+15);
            textFont(h1,headerFontSize);
            text("Baud/Port", column0,row2);
            // text("Port Name", column0,row3);
            text("Filters",column0,row3);
        }
        popStyle();

    }

    void initialize_UI() {
        cp5_networking = new ControlP5(pApplet);
        cp5_networking_dropdowns = new ControlP5(pApplet);
        cp5_networking_baudRate = new ControlP5(pApplet);
        cp5_networking_portName = new ControlP5(pApplet);

        /* Textfields */
        // OSC
        createTextFields(oscTextFieldNames, oscTextDefaultVals);
        // UDP
        createTextFields(udpTextFieldNames, udpTextDefaultVals);
        // LSL
        createTextFields(lslTextFieldNames, lslTextDefaultVals);

        // Serial
        //grab list of existing serial port options and store into Arrays.list...
        createPortDropdown("port_name", comPorts);
        createBaudDropdown("baud_rate", baudRates);
        /* General Elements */

        createRadioButtons("filter1");
        createRadioButtons("filter2");
        createRadioButtons("filter3");
        createRadioButtons("filter4");

        for (int i = 0; i < datatypeNames.length; i++) {
            createDropdown(datatypeNames[i], dataTypes);
        }

        // Start Button
        startButton = new Button(x + w/2 - 70,y+h-40,200,20,"Start",14);
        startButton.setFont(p4,14);
        startButton.setColorNotPressed(color(184,220,105));
        startButton.setHelpText("Click here to Start and Stop the network stream for the chosen protocol.");

        // Networking Data Type Guide button
        guideButton = new Button(x0 + 2, y0 + navH + 2, 150, navH - 6,"Open Networking Guide",14);
        guideButton.setCornerRoundess((int)(navHeight-6));
        guideButton.setFont(p5,12);
        guideButton.setColorNotPressed(color(57,128,204));
        guideButton.setFontColorNotActive(color(255));
        guideButton.setHelpText("Click this button to open the Networking Widget Guide in your default browser.");
        guideButton.setURL(networkingGuideURL);
        guideButton.hasStroke(false);
    }

    /* Shows and Hides appropriate CP5 elements within widget */
    void showCP5() {

        osc_visible=false;
        udp_visible=false;
        lsl_visible=false;
        serial_visible=false;

        if (protocolMode.equals("OSC")) {
            osc_visible = true;
        } else if (protocolMode.equals("UDP")) {
            udp_visible = true;
        } else if (protocolMode.equals("LSL")) {
            lsl_visible = true;
        } else if (protocolMode.equals("Serial")) {
            serial_visible = true;
        }

        setTextFieldVisible(oscTextFieldNames, osc_visible);
        setTextFieldVisible(udpTextFieldNames, udp_visible);
        setTextFieldVisible(lslTextFieldNames, lsl_visible);

        cp5_networking_portName.get(ScrollableList.class, "port_name").setVisible(serial_visible);
        cp5_networking_baudRate.get(ScrollableList.class, "baud_rate").setVisible(serial_visible);

        cp5_networking_dropdowns.get(ScrollableList.class, "dataType1").setVisible(true);
        if (!serial_visible) {
            cp5_networking_dropdowns.get(ScrollableList.class, "dataType2").setVisible(true);
            cp5_networking_dropdowns.get(ScrollableList.class, "dataType3").setVisible(true);
        } else{
            cp5_networking_dropdowns.get(ScrollableList.class, "dataType2").setVisible(false);
            cp5_networking_dropdowns.get(ScrollableList.class, "dataType3").setVisible(false);
        }

        //Draw a 4th Data Type dropdown menu if we are using OSC!
        if (protocolMode.equals("OSC")) {
            cp5_networking_dropdowns.get(ScrollableList.class, "dataType4").setVisible(true);
        } else {
            cp5_networking_dropdowns.get(ScrollableList.class, "dataType4").setVisible(false);
        }

        cp5_networking.get(RadioButton.class, "filter1").setVisible(true);
        if (!serial_visible) {
            cp5_networking.get(RadioButton.class, "filter2").setVisible(true);
            cp5_networking.get(RadioButton.class, "filter3").setVisible(true);
        } else {
            cp5_networking.get(RadioButton.class, "filter2").setVisible(false);
            cp5_networking.get(RadioButton.class, "filter3").setVisible(false);
        }
        //Draw a 4th Filter button option if we are using OSC!
        if (protocolMode.equals("OSC")) {
            cp5_networking.get(RadioButton.class, "filter4").setVisible(true);
        } else {
            cp5_networking.get(RadioButton.class, "filter4").setVisible(false);
        }
    }

    void setTextFieldVisible(String[] textFieldNames, boolean isVisible) {
        for (int i = 0; i < textFieldNames.length; i++) {
            cp5_networking.get(Textfield.class, textFieldNames[i]).setVisible(isVisible);
        }
    }

    //Lock text fields by setting _lock = true, unlock using false
    void lockTextFields(String[] textFieldNames, boolean _lock) {
        for (int i = 0; i < textFieldNames.length; i++) {
            if (_lock) {
                cp5_networking.get(Textfield.class, textFieldNames[i]).lock();
            } else {
                cp5_networking.get(Textfield.class, textFieldNames[i]).unlock();
            }
        }
    }

    void createTextFields(String[] textFieldNames, String[] defaultValues) {
        for (int i = 0; i < textFieldNames.length; i++) {
            createTextField(textFieldNames[i], defaultValues[i]);
        }
    }

    /* Create textfields for network parameters */
    void createTextField(String name, String default_text) {
        cp5_networking.addTextfield(name)
            .align(10,100,10,100)                   // Alignment
            .setSize(120,20)                         // Size of textfield
            .setFont(f2)
            .setFocus(false)                        // Deselects textfield
            .setColor(color(26,26,26))
            .setColorBackground(color(255,255,255)) // text field bg color
            .setColorValueLabel(color(0,0,0))       // text color
            .setColorForeground(color(26,26,26))    // border color when not selected
            .setColorActive(isSelected_color)       // border color when selected
            .setColorCursor(color(26,26,26))
            .setText(default_text)                  // Default text in the field
            .setCaptionLabel("")                    // Remove caption label
            .setVisible(false)                      // Initially hidden
            .setAutoClear(true)                     // Autoclear
            ;
    }

    /* Create radio buttons for filter toggling */
    void createRadioButtons(String name) {
        String id = name.substring(name.length()-1);
        cp5_networking.addRadioButton(name)
                .setSize(10,10)
                .setColorForeground(color(120))
                .setColorBackground(color(200,200,200)) // text field bg color
                .setColorActive(color(184,220,105))
                .setColorLabel(color(0))
                .setItemsPerRow(2)
                .setSpacingColumn(40)
                .addItem(id + "-Off", 0)
                .addItem(id + "-On", 1)
                // .addItem("Off",0)
                // .addItem("On",1)
                .activate(0)
                .setVisible(false)
                ;
    }

    /* Creating DataType Dropdowns */
    void createDropdown(String name, List<String> _items) {

        cp5_networking_dropdowns.addScrollableList(name)
                .setOpen(false)

                .setColorBackground(color(31,69,110)) // text field bg color
                .setColorValueLabel(color(255))       // text color
                .setColorCaptionLabel(color(255))
                .setColorForeground(color(125))    // border color when not selected
                .setColorActive(color(150, 170, 200))       // border color when selected
                // .setColorCursor(color(26,26,26))

                .setSize(itemWidth,(_items.size()+1)*(navH-4))// + maxFreqList.size())
                .setBarHeight(navH-4) //height of top/primary bar
                .setItemHeight(navH-4) //height of all item/dropdown bars
                .addItems(_items) // used to be .addItems(maxFreqList)
                .setVisible(false)
                ;
        cp5_networking_dropdowns.getController(name)
            .getCaptionLabel() //the caption label is the text object in the primary bar
            .toUpperCase(false) //DO NOT AUTOSET TO UPPERCASE!!!
            .setText("None")
            .setFont(h4)
            .setSize(14)
            .getStyle() //need to grab style before affecting the paddingTop
            .setPaddingTop(4)
            ;
        cp5_networking_dropdowns.getController(name)
            .getValueLabel() //the value label is connected to the text objects in the dropdown item bars
            .toUpperCase(false) //DO NOT AUTOSET TO UPPERCASE!!!
            .setText("None")
            .setFont(h5)
            .setSize(12) //set the font size of the item bars to 14pt
            .getStyle() //need to grab style before affecting the paddingTop
            .setPaddingTop(3) //4-pixel vertical offset to center text
            ;
    }

    void createBaudDropdown(String name, List<String> _items) {
        cp5_networking_baudRate.addScrollableList(name)
                .setOpen(false)

                .setColorBackground(color(31,69,110)) // text field bg color
                .setColorValueLabel(color(255))       // text color
                .setColorCaptionLabel(color(255))
                .setColorForeground(color(125))    // border color when not selected
                .setColorActive(color(150, 170, 200))       // border color when selected
                // .setColorCursor(color(26,26,26))

                .setSize(itemWidth,(_items.size()+1)*(navH-4))// + maxFreqList.size())
                .setBarHeight(navH-4) //height of top/primary bar
                .setItemHeight(navH-4) //height of all item/dropdown bars
                .addItems(_items) // used to be .addItems(maxFreqList)
                .setVisible(false)
                ;
        cp5_networking_baudRate.getController(name)
            .getCaptionLabel() //the caption label is the text object in the primary bar
            .toUpperCase(false) //DO NOT AUTOSET TO UPPERCASE!!!
            .setText(defaultBaud)
            .setFont(h4)
            .setSize(14)
            .getStyle() //need to grab style before affecting the paddingTop
            .setPaddingTop(4)
            ;
        cp5_networking_baudRate.getController(name)
            .getValueLabel() //the value label is connected to the text objects in the dropdown item bars
            .toUpperCase(false) //DO NOT AUTOSET TO UPPERCASE!!!
            .setText("None")
            .setFont(h5)
            .setSize(12) //set the font size of the item bars to 14pt
            .getStyle() //need to grab style before affecting the paddingTop
            .setPaddingTop(3) //4-pixel vertical offset to center text
            ;
    }

    void createPortDropdown(String name, List<String> _items) {
        cp5_networking_portName.addScrollableList(name)
            .setOpen(false)
            .setColorBackground(color(31,69,110)) // text field bg color
            .setColorValueLabel(color(255))       // text color
            .setColorCaptionLabel(color(255))
            .setColorForeground(color(125))    // border color when not selected
            .setColorActive(color(150, 170, 200))       // border color when selected
            // .setColorCursor(color(26,26,26))
            .setSize(itemWidth,(_items.size()+1)*(navH-4))// + maxFreqList.size())
            .setBarHeight(navH-4) //height of top/primary bar
            .setItemHeight(navH-4) //height of all item/dropdown bars
            .addItems(_items) // used to be .addItems(maxFreqList)
            .setVisible(false)
            ;
        cp5_networking_portName.getController(name)
            .getCaptionLabel() //the caption label is the text object in the primary bar
            .toUpperCase(false) //DO NOT AUTOSET TO UPPERCASE!!!
            .setText("None")
            .setFont(h4)
            .setSize(14)
            .getStyle() //need to grab style before affecting the paddingTop
            .setPaddingTop(4)
            ;
        cp5_networking_portName.getController(name)
            .getValueLabel() //the value label is connected to the text objects in the dropdown item bars
            .toUpperCase(false) //DO NOT AUTOSET TO UPPERCASE!!!
            .setText("None")
            .setFont(h5)
            .setSize(12) //set the font size of the item bars to 14pt
            .getStyle() //need to grab style before affecting the paddingTop
            .setPaddingTop(3) //4-pixel vertical offset to center text
            ;
    }

    void screenResized() {
        super.screenResized();

        cp5_networking.setGraphics(pApplet, 0,0);
        cp5_networking_dropdowns.setGraphics(pApplet, 0,0);
        cp5_networking_baudRate.setGraphics(pApplet, 0,0);
        cp5_networking_portName.setGraphics(pApplet, 0,0);

        column0 = x+w/22-12;
        int widthd = 46;//This value has been fine-tuned to look proper in windowed mode 1024*768 and fullscreen on 1920x1080
        column1 = x+12*w/widthd-25;//This value has been fine-tuned to look proper in windowed mode 1024*768 and fullscreen on 1920x1080
        column2 = x+(12+9*1)*w/widthd-25;
        column3 = x+(12+9*2)*w/widthd-25;
        column4 = x+(12+9*3)*w/widthd-25;
        halfWidth = (column2+100) - column1;
        fullColumnWidth = (column4+100) - column1;
        row0 = y+h/4+10;
        row1 = y+4*h/10;
        row2 = y+5*h/10;
        row3 = y+6*h/10;
        row4 = y+7*h/10;
        row5 = y+8*h/10;
        int offset = 15;//This value has been fine-tuned to look proper in windowed mode 1024*768 and fullscreen on 1920x1080

        //reset the button positions using new x and y
        startButton.setPos(x + w/2 - 70, y + h - 40 );
        guideButton.setPos(x0 + 2, y0 + navH + 2);

        //scale the item width of all elements in the networking widget
        itemWidth = int(map(width, 1024, 1920, 100, 120)) - 4;
        
        int dropdownsItemsToShow = int((this.h0 * datatypeDropdownScaling) / (this.navH - 4));
        println("Networking Data Types || show num dropdowns = " + dropdownsItemsToShow);
        int dropdownHeight = (dropdownsItemsToShow + 1) * (this.navH - 4);
        int maxDropdownHeight = (settings.nwDataTypesArray.length + 1) * (this.navH - 4);
        if (dropdownHeight > maxDropdownHeight) dropdownHeight = maxDropdownHeight;

        for (String datatypeName : datatypeNames) {
            cp5_networking_dropdowns.get(ScrollableList.class, datatypeName).setSize(itemWidth, dropdownHeight);
        }

        if (protocolMode.equals("OSC")) {
            for (String textField : oscTextFieldNames) {
                cp5_networking.get(Textfield.class, textField).setWidth(itemWidth);
            }
            cp5_networking.get(Textfield.class, "OSC_ip1").setPosition(column1, row2 - offset);
            cp5_networking.get(Textfield.class, "OSC_port1").setPosition(column1, row3 - offset);
            cp5_networking.get(Textfield.class, "OSC_address1").setPosition(column1, row4 - offset);
            cp5_networking.get(Textfield.class, "OSC_ip2").setPosition(column2, row2 - offset);
            cp5_networking.get(Textfield.class, "OSC_port2").setPosition(column2, row3 - offset);
            cp5_networking.get(Textfield.class, "OSC_address2").setPosition(column2, row4 - offset);
            cp5_networking.get(Textfield.class, "OSC_ip3").setPosition(column3, row2 - offset);
            cp5_networking.get(Textfield.class, "OSC_port3").setPosition(column3, row3 - offset);
            cp5_networking.get(Textfield.class, "OSC_address3").setPosition(column3, row4 - offset);
            cp5_networking.get(Textfield.class, "OSC_ip4").setPosition(column4, row2 - offset);
            cp5_networking.get(Textfield.class, "OSC_port4").setPosition(column4, row3 - offset);
            cp5_networking.get(Textfield.class, "OSC_address4").setPosition(column4, row4 - offset); //adding forth column only for OSC
            cp5_networking.get(RadioButton.class, "filter1").setPosition(column1, row5 - 10);
            cp5_networking.get(RadioButton.class, "filter2").setPosition(column2, row5 - 10);
            cp5_networking.get(RadioButton.class, "filter3").setPosition(column3, row5 - 10);
            cp5_networking.get(RadioButton.class, "filter4").setPosition(column4, row5 - 10);
        } else if (protocolMode.equals("UDP")) {
            for (String textField : udpTextFieldNames) {
                cp5_networking.get(Textfield.class, textField).setWidth(itemWidth);
            }
            cp5_networking.get(Textfield.class, "UDP_ip1").setPosition(column1, row2 - offset);
            cp5_networking.get(Textfield.class, "UDP_port1").setPosition(column1, row3 - offset);
            cp5_networking.get(Textfield.class, "UDP_ip2").setPosition(column2, row2 - offset);
            cp5_networking.get(Textfield.class, "UDP_port2").setPosition(column2, row3 - offset);
            cp5_networking.get(Textfield.class, "UDP_ip3").setPosition(column3, row2 - offset);
            cp5_networking.get(Textfield.class, "UDP_port3").setPosition(column3, row3 - offset);
            cp5_networking.get(RadioButton.class, "filter1").setPosition(column1, row4 - 10);
            cp5_networking.get(RadioButton.class, "filter2").setPosition(column2, row4 - 10);
            cp5_networking.get(RadioButton.class, "filter3").setPosition(column3, row4 - 10);
        } else if (protocolMode.equals("LSL")) {
            for (String textField : lslTextFieldNames) {
                cp5_networking.get(Textfield.class, textField).setWidth(itemWidth);
            }
            cp5_networking.get(Textfield.class, "LSL_name1").setPosition(column1,row2 - offset);
            cp5_networking.get(Textfield.class, "LSL_type1").setPosition(column1,row3 - offset);
            cp5_networking.get(Textfield.class, "LSL_numchan1").setPosition(column1,row4 - offset);
            cp5_networking.get(Textfield.class, "LSL_name2").setPosition(column2,row2 - offset);
            cp5_networking.get(Textfield.class, "LSL_type2").setPosition(column2,row3 - offset);
            cp5_networking.get(Textfield.class, "LSL_numchan2").setPosition(column2,row4 - offset);
            cp5_networking.get(Textfield.class, "LSL_name3").setPosition(column3,row2 - offset);
            cp5_networking.get(Textfield.class, "LSL_type3").setPosition(column3,row3 - offset);
            cp5_networking.get(Textfield.class, "LSL_numchan3").setPosition(column3,row4 - offset);
            cp5_networking.get(RadioButton.class, "filter1").setPosition(column1, row5 - 10);
            cp5_networking.get(RadioButton.class, "filter2").setPosition(column2, row5 - 10);
            cp5_networking.get(RadioButton.class, "filter3").setPosition(column3, row5 - 10);
        } else if (protocolMode.equals("Serial")) {
            //Serial Specific
            cp5_networking_baudRate.get(ScrollableList.class, "baud_rate").setPosition(column1, row2-offset);
            // cp5_networking_portName.get(ScrollableList.class, "port_name").setPosition(column1, row3-offset);
            cp5_networking_portName.get(ScrollableList.class, "port_name").setPosition(column2, row2-offset);
            cp5_networking_baudRate.get(ScrollableList.class, "baud_rate").setSize(itemWidth, (baudRates.size()+1)*(navH-4));
            // cp5_networking_portName.get(ScrollableList.class, "port_name").setSize(fullColumnWidth, (comPorts.size()+1)*(navH-4));
            // cp5_networking_portName.get(ScrollableList.class, "port_name").setSize(fullColumnWidth, (4)*(navH-4)); //
            cp5_networking_portName.get(ScrollableList.class, "port_name").setSize(halfWidth, (5)*(navH-4)); //halfWidth
            cp5_networking.get(RadioButton.class, "filter1").setPosition(column1, row3 - 10);
        }

        cp5_networking_dropdowns.get(ScrollableList.class, "dataType1").setPosition(column1, row1-offset);
        cp5_networking_dropdowns.get(ScrollableList.class, "dataType2").setPosition(column2, row1-offset);
        cp5_networking_dropdowns.get(ScrollableList.class, "dataType3").setPosition(column3, row1-offset);
        cp5_networking_dropdowns.get(ScrollableList.class, "dataType4").setPosition(column4, row1-offset);
    }

    void mousePressed() {
        super.mousePressed(); //calls the parent mousePressed() method of Widget (DON'T REMOVE)
        if (startButton.isMouseHere()) {
            startButton.setIsActive(true);
        } else if (guideButton.isMouseHere()) {
            guideButton.setIsActive(true);
        }
    }

    void mouseReleased() {
        super.mouseReleased(); //calls the parent mouseReleased() method of Widget (DON'T REMOVE)

        // If start button was pressed...
        if (startButton.isActive && startButton.isMouseHere()) {
            if (!networkActive) {
                try {
                    turnOnButton();         // Change appearance of button
                    initializeStreams();    // Establish stream
                    startNetwork();         // Begin streaming
                    output("Network Stream Started");
                } catch (Exception e) {
                    //e.printStackTrace();
                    String exception = e.toString();
                    String [] nwError = split(exception, ':');
                    outputError("Networking Error - Port: " + nwError[2]);
                    shutDown();
                    networkActive = false;
                    return;
                }
            } else {
	                turnOffButton();        // Change apppearance of button
	                stopNetwork();          // Stop streams
	                output("Network Stream Stopped");
            }
        // or if the networking guide button was pressed...
        } else if (guideButton.isActive && guideButton.isMouseHere()) {
            guideButton.goToURL();
            output("Opening Networking Output Guide using default browser.");
        }
        startButton.setIsActive(false);
        guideButton.setIsActive(false);
    }

    void hideAllTextFields(String[] textFieldNames) {
        for (int i = 0; i < textFieldNames.length; i++) {
            cp5_networking.get(Textfield.class, textFieldNames[i]).setVisible(false);
        }
    }

    /* Function call to hide all widget CP5 elements */
    void hideElements() {
        String[] allTextFields = concat(oscTextFieldNames, udpTextFieldNames);
        allTextFields = concat(allTextFields, lslTextFieldNames);
        hideAllTextFields(allTextFields);

        cp5_networking_dropdowns.get(ScrollableList.class, "dataType1").setVisible(false);
        cp5_networking_dropdowns.get(ScrollableList.class, "dataType2").setVisible(false);
        cp5_networking_dropdowns.get(ScrollableList.class, "dataType3").setVisible(false);
        cp5_networking_dropdowns.get(ScrollableList.class, "dataType4").setVisible(false);
        cp5_networking_portName.get(ScrollableList.class, "port_name").setVisible(false);
        cp5_networking_baudRate.get(ScrollableList.class, "baud_rate").setVisible(false);

        cp5_networking.get(RadioButton.class, "filter1").setVisible(false);
        cp5_networking.get(RadioButton.class, "filter2").setVisible(false);
        cp5_networking.get(RadioButton.class, "filter3").setVisible(false);
        cp5_networking.get(RadioButton.class, "filter4").setVisible(false);

    }

    /* Change appearance of Button to off */
    void turnOffButton() {
        startButton.setColorNotPressed(color(184,220,105));
        startButton.setString("Start");
    }

    void turnOnButton() {
        startButton.setColorNotPressed(color(224, 56, 45));
        startButton.setString("Stop");
    }

    boolean getNetworkActive() {
        return networkActive;
    }

    /* Call to shutdown some UI stuff. Called from W_manager, maybe do this differently.. */
    void shutDown() {
        hideElements();
        turnOffButton();
    }

    void initializeStreams() {
        String ip;
        int port;
        String address;
        int filt_pos;
        String name;
        int nChanLSL;
        int baudRate;
        String type;

        String dt1 = settings.nwDataTypesArray[(int)cp5_networking_dropdowns.get(ScrollableList.class, "dataType1").getValue()];
        String dt2 = settings.nwDataTypesArray[(int)cp5_networking_dropdowns.get(ScrollableList.class, "dataType2").getValue()];
        String dt3 = settings.nwDataTypesArray[(int)cp5_networking_dropdowns.get(ScrollableList.class, "dataType3").getValue()];
        String dt4 = settings.nwDataTypesArray[(int)cp5_networking_dropdowns.get(ScrollableList.class, "dataType4").getValue()];
        networkActive = true;

        // Establish OSC Streams
        if (protocolMode.equals("OSC")) {
            if (!dt1.equals("None")) {
                ip = cp5_networking.get(Textfield.class, "OSC_ip1").getText();
                port = Integer.parseInt(cp5_networking.get(Textfield.class, "OSC_port1").getText());
                address = cp5_networking.get(Textfield.class, "OSC_address1").getText();
                filt_pos = (int)cp5_networking.get(RadioButton.class, "filter1").getValue();
                stream1 = new Stream(dt1, ip, port, address, filt_pos, nchan);
            } else {
                stream1 = null;
            }
            if (!dt2.equals("None")) {
                ip = cp5_networking.get(Textfield.class, "OSC_ip2").getText();
                port = Integer.parseInt(cp5_networking.get(Textfield.class, "OSC_port2").getText());
                address = cp5_networking.get(Textfield.class, "OSC_address2").getText();
                filt_pos = (int)cp5_networking.get(RadioButton.class, "filter2").getValue();
                stream2 = new Stream(dt2, ip, port, address, filt_pos, nchan);
            } else {
                stream2 = null;
            }
            if (!dt3.equals("None")) {
                ip = cp5_networking.get(Textfield.class, "OSC_ip3").getText();
                port = Integer.parseInt(cp5_networking.get(Textfield.class, "OSC_port3").getText());
                address = cp5_networking.get(Textfield.class, "OSC_address3").getText();
                filt_pos = (int)cp5_networking.get(RadioButton.class, "filter3").getValue();
                stream3 = new Stream(dt3, ip, port, address, filt_pos, nchan);
            } else {
                stream3 = null;
            }
            if (!dt4.equals("None")) {
                ip = cp5_networking.get(Textfield.class, "OSC_ip4").getText();
                port = Integer.parseInt(cp5_networking.get(Textfield.class, "OSC_port4").getText());
                address = cp5_networking.get(Textfield.class, "OSC_address4").getText();
                filt_pos = (int)cp5_networking.get(RadioButton.class, "filter4").getValue();
                stream4 = new Stream(dt4, ip, port, address, filt_pos, nchan);
            } else {
                stream4 = null;
            }

            // Establish UDP Streams
        } else if (protocolMode.equals("UDP")) {
            if (!dt1.equals("None")) {
                ip = cp5_networking.get(Textfield.class, "UDP_ip1").getText();
                port = Integer.parseInt(cp5_networking.get(Textfield.class, "UDP_port1").getText());
                filt_pos = (int)cp5_networking.get(RadioButton.class, "filter1").getValue();
                stream1 = new Stream(dt1, ip, port, filt_pos, nchan);
            } else {
                stream1 = null;
            }
            if (!dt2.equals("None")) {
                ip = cp5_networking.get(Textfield.class, "UDP_ip2").getText();
                port = Integer.parseInt(cp5_networking.get(Textfield.class, "UDP_port2").getText());
                filt_pos = (int)cp5_networking.get(RadioButton.class, "filter2").getValue();
                stream2 = new Stream(dt2, ip, port, filt_pos, nchan);
            } else {
                stream2 = null;
            }
            if (!dt3.equals("None")) {
                ip = cp5_networking.get(Textfield.class, "UDP_ip3").getText();
                port = Integer.parseInt(cp5_networking.get(Textfield.class, "UDP_port3").getText());
                filt_pos = (int)cp5_networking.get(RadioButton.class, "filter3").getValue();
                stream3 = new Stream(dt3, ip, port, filt_pos, nchan);
            } else {
                stream3 = null;
            }

            // Establish LSL Streams
        } else if (protocolMode.equals("LSL")) {
            if (!dt1.equals("None")) {
                name = cp5_networking.get(Textfield.class, "LSL_name1").getText();
                type = cp5_networking.get(Textfield.class, "LSL_type1").getText();
                nChanLSL = Integer.parseInt(cp5_networking.get(Textfield.class, "LSL_numchan1").getText());
                filt_pos = (int)cp5_networking.get(RadioButton.class, "filter1").getValue();
                stream1 = new Stream(dt1, name, type, nChanLSL, filt_pos, nchan);
            } else {
                stream1 = null;
            }
            if (!dt2.equals("None")) {
                name = cp5_networking.get(Textfield.class, "LSL_name2").getText();
                type = cp5_networking.get(Textfield.class, "LSL_type2").getText();
                nChanLSL = Integer.parseInt(cp5_networking.get(Textfield.class, "LSL_numchan2").getText());
                filt_pos = (int)cp5_networking.get(RadioButton.class, "filter2").getValue();
                stream2 = new Stream(dt2, name, type, nChanLSL, filt_pos, nchan);
            } else {
                stream2 = null;
            }
            if (!dt3.equals("None")) {
                name = cp5_networking.get(Textfield.class, "LSL_name3").getText();
                type = cp5_networking.get(Textfield.class, "LSL_type3").getText();
                nChanLSL = Integer.parseInt(cp5_networking.get(Textfield.class, "LSL_numchan3").getText());
                filt_pos = (int)cp5_networking.get(RadioButton.class, "filter3").getValue();
                stream3 = new Stream(dt3, name, type, nChanLSL, filt_pos, nchan);
            } else {
                stream3 = null;
            }
        } else if (protocolMode.equals("Serial")) {
            // %%%%%
            if (!dt1.equals("None")) {
                name = comPorts.get((int)(cp5_networking_portName.get(ScrollableList.class, "port_name").getValue()));
                println("ComPort: " + name);
                // name = cp5_networking_portName.get(ScrollableList.class, "port_name").getItem((int)cp5_networking_portName.get(ScrollableList.class, "port_name").getValue());
                println("Baudrate: " + Integer.parseInt(baudRates.get((int)(cp5_networking_baudRate.get(ScrollableList.class, "baud_rate").getValue()))));
                baudRate = Integer.parseInt(baudRates.get((int)(cp5_networking_baudRate.get(ScrollableList.class, "baud_rate").getValue())));

                filt_pos = (int)cp5_networking.get(RadioButton.class, "filter1").getValue();
                stream1 = new Stream(dt1, name, baudRate, filt_pos, pApplet, nchan);  //String dataType, String portName, int baudRate, int filter, PApplet _this
            } else {
                stream1 = null;
            }
        }
    }

    /* Start networking */
    void startNetwork() {
        if (stream1!=null) {
            stream1.start();
        }
        if (stream2!=null) {
            stream2.start();
        }
        if (stream3!=null) {
            stream3.start();
        }
        if (stream4!=null) {
            stream4.start();
        }
    }

    /* Stop networking */
    void stopNetwork() {
        networkActive = false;

        if (stream1!=null) {
            stream1.quit();
            stream1=null;
        }
        if (stream2!=null) {
            stream2.quit();
            stream2=null;
        }
        if (stream3!=null) {
            stream3.quit();
            stream3=null;
        }
        if (stream4!=null) {
            stream4.quit();
            stream4=null;
        }
    }

    void clearCP5() {
        //clears all controllers from ControlP5 instance...
        w_networking.cp5_networking.dispose();
        w_networking.cp5_networking_dropdowns.dispose();
        println("clearing cp5_networking...");
    }

    void closeAllDropdowns() {
        dataDropdownsShouldBeClosed = true;
        w_networking.cp5_networking_dropdowns.get(ScrollableList.class, "dataType1").close();
        w_networking.cp5_networking_dropdowns.get(ScrollableList.class, "dataType2").close();
        w_networking.cp5_networking_dropdowns.get(ScrollableList.class, "dataType3").close();
        w_networking.cp5_networking_dropdowns.get(ScrollableList.class, "dataType4").close();
        w_networking.cp5_networking_baudRate.get(ScrollableList.class, "baud_rate").close();
        w_networking.cp5_networking_portName.get(ScrollableList.class, "port_name").close();
        //since this method is called when items are selected, go ahead and save settings to HashMap via fetchCP5Data
        fetchCP5Data();
    }

    void openCloseDropdowns() {
        //datatype dropdowns
        for (int i = 0; i < datatypeNames.length; i++) {
            if (cp5_networking_dropdowns.get(ScrollableList.class, datatypeNames[i]).isOpen()) {
                if (!cp5_networking_dropdowns.getController(datatypeNames[i]).isMouseOver()) {
                    cp5_networking_dropdowns.get(ScrollableList.class, datatypeNames[i]).close();
                }
            }
            //If using a TopNav object, objects become locked and won't open
            if (!cp5_networking_dropdowns.get(ScrollableList.class, datatypeNames[i]).isOpen()) {
                if (cp5_networking_dropdowns.getController(datatypeNames[i]).isMouseOver()) {
                    cp5_networking_dropdowns.get(ScrollableList.class, datatypeNames[i]).open();
                }
            }
        }
        if (protocolMode.equals("Serial")) {
            //When using serial mode, lock baud rate dropdown when datatype dropdown is in use
            if (cp5_networking_dropdowns.get(ScrollableList.class, datatypeNames[0]).isOpen()) {
                cp5_networking_baudRate.get(ScrollableList.class, "baud_rate").lock();
            } else {
                if (cp5_networking_baudRate.get(ScrollableList.class, "baud_rate").isLock()) {
                    cp5_networking_baudRate.get(ScrollableList.class, "baud_rate").unlock();
                }
            }
            //baud rate
            if (cp5_networking_baudRate.get(ScrollableList.class, "baud_rate").isOpen()) {
                if (!cp5_networking_baudRate.getController("baud_rate").isMouseOver()) {
                    // println("2");
                    cp5_networking_baudRate.get(ScrollableList.class, "baud_rate").close();
                }
            }
            if (!cp5_networking_baudRate.get(ScrollableList.class, "baud_rate").isOpen()) {
                if (cp5_networking_baudRate.getController("baud_rate").isMouseOver()) {
                    // println("2");
                    cp5_networking_baudRate.get(ScrollableList.class, "baud_rate").open();
                }
            }
            //port name
            if (cp5_networking_portName.get(ScrollableList.class, "port_name").isOpen()) {
                if (!cp5_networking_portName.getController("port_name").isMouseOver()) {
                    // println("2");
                    cp5_networking_portName.get(ScrollableList.class, "port_name").close();
                }
            }
            if (!cp5_networking_portName.get(ScrollableList.class, "port_name").isOpen()) {
                if (cp5_networking_portName.getController("port_name").isMouseOver()) {
                    // println("2");
                    cp5_networking_portName.get(ScrollableList.class, "port_name").open();
                }
            }
        }
    }

    void checkTopNovEvents() {
        //Check if a change has occured in TopNav
        if ((topNav.configSelector.isVisible != configIsVisible) || (topNav.layoutSelector.isVisible != layoutIsVisible)) {
            //lock/unlock the controllers within networking widget when using TopNav Objects
            if (topNav.configSelector.isVisible || topNav.layoutSelector.isVisible) {
                cp5_networking_dropdowns.get(ScrollableList.class, "dataType1").lock();
                cp5_networking_dropdowns.get(ScrollableList.class, "dataType2").lock();
                cp5_networking_dropdowns.get(ScrollableList.class, "dataType3").lock();
                cp5_networking_dropdowns.get(ScrollableList.class, "dataType4").lock();
                cp5_networking_portName.getController("port_name").lock();
                lockTextFields(oscTextFieldNames, true);
                lockTextFields(udpTextFieldNames, true);
                lockTextFields(lslTextFieldNames, true);
                //println("##LOCKED NETWORKING CP5 CONTROLLERS##");
            } else {
                cp5_networking_dropdowns.get(ScrollableList.class, "dataType1").unlock();
                cp5_networking_dropdowns.get(ScrollableList.class, "dataType2").unlock();
                cp5_networking_dropdowns.get(ScrollableList.class, "dataType3").unlock();
                cp5_networking_dropdowns.get(ScrollableList.class, "dataType4").unlock();
                cp5_networking_portName.getController("port_name").unlock();
                lockTextFields(oscTextFieldNames, false);
                lockTextFields(udpTextFieldNames, false);
                lockTextFields(lslTextFieldNames, false);
            }
            configIsVisible = topNav.configSelector.isVisible;
            layoutIsVisible = topNav.layoutSelector.isVisible;
        }
    }

    public void setComPortToSave(int n) {
        comPortToSave = n;
    }

    public void disableCertainOutputs(int n) {
        //Disable serial fft ouput and display message, it's too much data for serial coms
        if (w_networking.protocolMode.equals("Serial")) {
            if (n == Arrays.asList(settings.nwDataTypesArray).indexOf("FFT")) {
                output("Please use Band Power instead of FFT for Serial Output. Changing data type...");
                println("Networking: Changing data type from FFT to BandPower. FFT data is too large to send over Serial coms.");
                cp5_networking_dropdowns.getController("dataType1").getCaptionLabel().setText("BandPower");
                cp5_networking_dropdowns.get(ScrollableList.class, "dataType1")
                            .setValue(Arrays.asList(settings.nwDataTypesArray).indexOf("BandPower"));
            };
        }
    }
}; //End of w_networking class

////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////

class Stream extends Thread {
    String protocol;
    String dataType;
    String ip;
    int port;
    String address;
    int filter;
    String streamType;
    String streamName;
    int nChanLSL;
    int numChan = 0;

    Boolean isStreaming;
    Boolean newData = false;
    // Data buffers
    int start = dataBuffY_filtY_uV[0].length-11;
    int end = dataBuffY_filtY_uV[0].length-1;
    int bufferLen = end-start;
    float[] dataToSend = new float[numChan*bufferLen];

    //OSC Objects
    OscP5 osc;
    NetAddress netaddress;
    OscMessage msg;
    //UDP Objects
    UDP udp;
    ByteBuffer buffer;
    // LSL objects
    LSL.StreamInfo info_data;
    LSL.StreamOutlet outlet_data;
    LSL.StreamInfo info_aux;
    LSL.StreamOutlet outlet_aux;

    // Serial objects %%%%%
    Serial serial_networking;
    String portName;
    int baudRate;
    String serialMessage = "";

    PApplet pApplet;

    private void updateNumChan(int _numChan) {
        numChan = _numChan;
        println("Stream update numChan to " + numChan);
        dataToSend = new float[numChan * nPointsPerUpdate];
        println("nPointsPerUpdate " + nPointsPerUpdate);
        println("dataToSend len: " + numChan * nPointsPerUpdate);
    }

    /* OSC Stream */
    Stream(String dataType, String ip, int port, String address, int filter, int _nchan) {
        this.protocol = "OSC";
        this.dataType = dataType;
        this.ip = ip;
        this.port = port;
        this.address = address;
        this.filter = filter;
        this.isStreaming = false;
        updateNumChan(_nchan);
        try {
            closeNetwork(); //make sure everything is closed!
        } catch (Exception e) {
        }
    }
    /*UDP Stream */
    Stream(String dataType, String ip, int port, int filter, int _nchan) {
        this.protocol = "UDP";
        this.dataType = dataType;
        this.ip = ip;
        this.port = port;
        this.filter = filter;
        this.isStreaming = false;
        updateNumChan(_nchan);
        if (this.dataType.equals("TimeSeries")) {
            buffer = ByteBuffer.allocate(4*numChan);
        } else {
            buffer = ByteBuffer.allocate(4*126);
        }
        try {
            closeNetwork(); //make sure everything is closed!
        } catch (Exception e) {
        }
    }
    /* LSL Stream */
    Stream(String dataType, String streamName, String streamType, int nChanLSL, int filter, int _nchan) {
        this.protocol = "LSL";
        this.dataType = dataType;
        this.streamName = streamName;
        this.streamType = streamType;
        this.nChanLSL = nChanLSL;
        this.filter = filter;
        this.isStreaming = false;
        updateNumChan(_nchan);
        try {
            closeNetwork(); //make sure everything is closed!
        } catch (Exception e) {
        }
    }

    // Serial Stream %%%%%
    Stream(String dataType, String portName, int baudRate, int filter, PApplet _this, int _nchan) {
        // %%%%%
        this.protocol = "Serial";
        this.dataType = dataType;
        this.portName = portName;
        this.baudRate = baudRate;
        this.filter = filter;
        this.isStreaming = false;
        this.pApplet = _this;
        updateNumChan(_nchan);
        if (this.dataType.equals("TimeSeries")) {
            buffer = ByteBuffer.allocate(4*numChan);
        } else {
            buffer = ByteBuffer.allocate(4*126);
        }

        try {
            closeNetwork();
        } catch (Exception e) {
            //nothing
        }
    }

    void start() {
        this.isStreaming = true;
        if (!this.protocol.equals("LSL")) {
            super.start();
        } else {
            openNetwork();
        }
    }

    void run() {
        if (!this.protocol.equals("LSL")) {
            openNetwork();
            while(this.isStreaming) {
                if (!isRunning) {
                    try {
                        Thread.sleep(1);
                    } catch (InterruptedException e) {
                        println(e.getMessage());
                    }
                } else {
                        if (checkForData()) {
                            if (this.dataType.equals("TimeSeries")) {
                                sendTimeSeriesData();
                            } else if (this.dataType.equals("FFT")) {
                                sendFFTData();
                            } else if (this.dataType.equals("EMG")) {
                                sendEMGData();
                            } else if (this.dataType.equals("BandPower")) {
                                sendPowerBandData();
                            } else if (this.dataType.equals("Accel/Aux")) {
                                if (eegDataSource == DATASOURCE_CYTON) {
                                    if (cyton.getBoardMode() == BoardMode.ANALOG) {
                                        sendAnalogReadData();
                                    } else if (cyton.getBoardMode() == BoardMode.DIGITAL) {
                                        sendDigitalReadData();
                                    } else {
                                        sendAccelerometerData();
                                    }
                                } else {
                                    sendAccelerometerData();
                                }
                            } else if (this.dataType.equals("Focus")) {
                                sendFocusData();
                            } else if (this.dataType.equals("Pulse")) {
                                sendPulseData();
                            } else if (this.dataType.equals("SSVEP")) {
                                sendSSVEPData();
                            }
                            setDataFalse();
                        } else {
                            try {
                                Thread.sleep(1);
                            } catch (InterruptedException e) {
                                println(e.getMessage());
                            }
                        }
                    }
                }
        } else if (this.protocol.equals("LSL")) {
            if (!isRunning) {
                try {
                    Thread.sleep(1);
                } catch (InterruptedException e) {
                    println(e.getMessage());
                }
            } else {
                if (checkForData()) {
                    if (this.dataType.equals("TimeSeries")) {
                        sendTimeSeriesData();
                    } else if (this.dataType.equals("FFT")) {
                        sendFFTData();
                    } else if (this.dataType.equals("EMG")) {
                        sendEMGData();
                    } else if (this.dataType.equals("BandPower")) {
                        sendPowerBandData();
                    } else if (this.dataType.equals("Accel/Aux")) {
                        if (eegDataSource == DATASOURCE_CYTON) {
                            if (cyton.getBoardMode() == BoardMode.ANALOG) {
                                sendAnalogReadData();
                            } else if (cyton.getBoardMode() == BoardMode.DIGITAL) {
                                sendDigitalReadData();
                            } else {
                                sendAccelerometerData();
                            }
                        } else {
                            sendAccelerometerData();
                        }
                    } else if (this.dataType.equals("Focus")) {
                        sendFocusData();
                    } else if (this.dataType.equals("Pulse")) {
                        sendPulseData();
                    } else if (this.dataType.equals("SSVEP")) {
                        sendSSVEPData();
                    }
                    //setDataFalse(); //Wait until all streams are done, Fixes 592
                }
            }
        }
    }

    Boolean checkForData() {
        if (this.dataType.equals("TimeSeries")) {
            return dataProcessing.newDataToSend;
        } else if (this.dataType.equals("FFT")) {
            return dataProcessing.newDataToSend;
        } else if (this.dataType.equals("EMG")) {
            return dataProcessing.newDataToSend;
        } else if (this.dataType.equals("BandPower")) {
            return dataProcessing.newDataToSend;
        } else if (this.dataType.equals("Accel/Aux")) {
            return dataProcessing.newDataToSend;
        } else if (this.dataType.equals("Focus")) {
            return dataProcessing.newDataToSend;
        } else if (this.dataType.equals("Pulse")) {
            return dataProcessing.newDataToSend;
        } else if (this.dataType.equals("SSVEP")) {
            return dataProcessing.newDataToSend;
        }
        return false;
    }

    void setDataFalse() {
        if (this.dataType.equals("TimeSeries")) {
            dataProcessing.newDataToSend = false;
        } else if (this.dataType.equals("FFT")) {
            dataProcessing.newDataToSend = false;
        } else if (this.dataType.equals("EMG")) {
            dataProcessing.newDataToSend = false;
        } else if (this.dataType.equals("BandPower")) {
            dataProcessing.newDataToSend = false;
        } else if (this.dataType.equals("Accel/Aux")) {
            dataProcessing.newDataToSend = false;
        } else if (this.dataType.equals("Focus")) {
            dataProcessing.newDataToSend = false;
        } else if (this.dataType.equals("Pulse")) {
            dataProcessing.newDataToSend = false;
        } else if (this.dataType.equals("SSVEP")) {
            dataProcessing.newDataToSend = false;
        }
    }

    /* This method contains all of the policies for sending data types */
    void sendTimeSeriesData() {

        // TIME SERIES UNFILTERED
        if (filter==0) {
            // OSC
            if (this.protocol.equals("OSC")) {
                for (int i=0;i<nPointsPerUpdate;i++) {
                    msg.clearArguments();
                    for (int j=0;j<numChan;j++) {
                        msg.add(yLittleBuff_uV[j][i]);
                    }
                    try {
                        this.osc.send(msg,this.netaddress);
                    } catch (Exception e) {
                        println(e.getMessage());
                    }
                }
                // UDP
            } else if (this.protocol.equals("UDP")) {
                for (int i=0;i<nPointsPerUpdate;i++) {
                    String outputter = "{\"type\":\"eeg\",\"data\":[";
                    for (int j = 0; j < numChan; j++) {
                        outputter += str(yLittleBuff_uV[j][i]);
                        if (j != numChan - 1) {
                            outputter += ",";
                        } else {
                            outputter += "]}\r\n";
                        }
                    }
                    try {
                        this.udp.send(outputter, this.ip, this.port);
                    } catch (Exception e) {
                        println(e.getMessage());
                    }
                }
                // LSL
            } else if (this.protocol.equals("LSL")) {
                for (int i=0; i<nPointsPerUpdate;i++) {
                    for (int j=0;j<numChan;j++) {
                        dataToSend[j+numChan*i] = yLittleBuff_uV[j][i];
                    }
                }
                // Add timestamp to LSL Stream
                // From LSLLink Library: The time stamps of other samples are automatically derived based on the sampling rate of the stream.
                outlet_data.push_chunk(dataToSend, System.currentTimeMillis());
                // SERIAL
            } else if (this.protocol.equals("Serial")) {         // Serial Output unfiltered
                for (int i=0;i<nPointsPerUpdate;i++) {
                    serialMessage = "["; //clear message
                    for (int j=0;j<numChan;j++) {
                        float chan_uV = yLittleBuff_uV[j][i];//get chan uV float value and truncate to 3 decimal places
                        String chan_uV_3dec = String.format("%.3f", chan_uV);
                        serialMessage += chan_uV_3dec;//  serialMesage += //add 3 decimal float chan uV value as string to serialMessage
                        if (j < numChan-1) {
                            serialMessage += ",";  //add a comma to serialMessage to separate chan values, as long as it isn't last value...
                        }
                    }
                    serialMessage += "]";  //close the message w/ "]"
                    try {
                        //  println(serialMessage);
                        this.serial_networking.write(serialMessage);          //write message to serial
                    } catch (Exception e) {
                        println(e.getMessage());
                    }
                }
            }


        // TIME SERIES FILTERED
        } else if (filter==1) {
            if (this.protocol.equals("OSC")) {
                for (int i=0;i<nPointsPerUpdate;i++) {
                    msg.clearArguments();
                    for (int j=0;j<numChan;j++) {
                        msg.add(dataBuffY_filtY_uV[j][start+i]);
                    }
                    try {
                        this.osc.send(msg,this.netaddress);
                    } catch (Exception e) {
                        println(e.getMessage());
                    }
                }
            } else if (this.protocol.equals("UDP")) {
                for (int i=0;i<nPointsPerUpdate;i++) {
                    String outputter = "{\"type\":\"eeg\",\"data\":[";
                    for (int j = 0; j < numChan; j++) {
                        outputter += str(dataBuffY_filtY_uV[j][start+i]);
                        if (j != numChan - 1) {
                            outputter += ",";
                        } else {
                            outputter += "]}\r\n";
                        }
                    }
                    try {
                        this.udp.send(outputter, this.ip, this.port);
                    } catch (Exception e) {
                        println(e.getMessage());
                    }
                }
            } else if (this.protocol.equals("LSL")) {
                for (int i=0; i<nPointsPerUpdate;i++) {
                    for (int j=0;j<numChan;j++) {
                        dataToSend[j+numChan*i] = dataBuffY_filtY_uV[j][i];
                    }
                }
                // Add timestamp to LSL Stream
                outlet_data.push_chunk(dataToSend, System.currentTimeMillis());
            } else if (this.protocol.equals("Serial")) {
                for (int i=0;i<nPointsPerUpdate;i++) {
                    serialMessage = "["; //clear message
                    for (int j=0;j<numChan;j++) {
                        float chan_uV_filt = dataBuffY_filtY_uV[j][start+i];//get chan uV float value and truncate to 3 decimal places
                        String chan_uV_filt_3dec = String.format("%.3f", chan_uV_filt);
                        serialMessage += chan_uV_filt_3dec;//  serialMesage += //add 3 decimal float chan uV value as string to serialMessage
                        if (j < numChan-1) {
                            serialMessage += ",";  //add a comma to serialMessage to separate chan values, as long as it isn't last value...
                        }
                    }
                    serialMessage += "]";  //close the message w/ "]"
                    try {
                        //  println(serialMessage);
                        this.serial_networking.write(serialMessage);          //write message to serial
                    } catch (Exception e) {
                        println(e.getMessage());
                    }
                }
            }
        }
    }

    void sendFFTData() {
        // UNFILTERED
        if (this.filter==0 || this.filter==1) {
            // OSC
            if (this.protocol.equals("OSC")) {
                for (int i=0;i<numChan;i++) {
                    msg.clearArguments();
                    msg.add(i+1);
                    for (int j=0;j<125;j++) {
                        msg.add(fftBuff[i].getBand(j));
                    }
                    try {
                        this.osc.send(msg,this.netaddress);
                    } catch (Exception e) {
                        println(e.getMessage());
                    }
                }
                // UDP
            } else if (this.protocol.equals("UDP")) {
                String outputter = "{\"type\":\"fft\",\"data\":[[";
                for (int i = 0;i < numChan; i++) {
                    for (int j = 0; j < 125; j++) {
                        outputter += str(fftBuff[i].getBand(j));
                        if (j != 125 - 1) {
                            outputter += ",";
                        }
                    }
                    if (i != numChan - 1) {
                        outputter += "],[";
                    } else {
                        outputter += "]]}\r\n";
                    }
                }
                try {
                    this.udp.send(outputter, this.ip, this.port);
                } catch (Exception e) {
                    println(e.getMessage());
                }
                // LSL
            } else if (this.protocol.equals("LSL")) {
                float[] _dataToSend = new float[numChan * 125];
                for (int i = 0; i < numChan; i++) {
                    for (int j = 0; j < 125; j++) {
                        _dataToSend[j+125*i] = fftBuff[i].getBand(j);
                    }
                }
                // Add timestamp to LSL Stream
                // From LSLLink Library: The time stamps of other samples are automatically derived based on the sampling rate of the stream.
                outlet_data.push_chunk(_dataToSend, System.currentTimeMillis());
            } else if (this.protocol.equals("Serial")) {
                /////////////////////////////////THIS OUTPUT IS DISABLED
                // Send FFT Data over Serial ... 
                /*
                for (int i=0;i<numChan;i++) {
                    serialMessage = "[" + (i+1) + ","; //clear message
                    for (int j=0;j<125;j++) {
                        float fft_band = fftBuff[i].getBand(j);
                        String fft_band_3dec = String.format("%.3f", fft_band);
                        serialMessage += fft_band_3dec;
                        if (j < 125-1) {
                            serialMessage += ",";  //add a comma to serialMessage to separate chan values, as long as it isn't last value...
                        }
                    }
                    serialMessage += "]";
                    try {
                        // println(serialMessage);
                        this.serial_networking.write(serialMessage);
                    } catch (Exception e) {
                        println(e.getMessage());
                    }
                }
                */
            }
        }
    }

    void sendPowerBandData() {
        // UNFILTERED & FILTERED ... influenced globally by the FFT filters dropdown ... just like the FFT data
        int numBandPower = 5; //DELTA, THETA, ALPHA, BETA, GAMMA

        if (this.filter==0 || this.filter==1) {
            // OSC
            if (this.protocol.equals("OSC")) {
                for (int i=0;i<numChan;i++) {
                    msg.clearArguments();
                    msg.add(i+1);
                    for (int j=0;j<numBandPower;j++) {
                        msg.add(dataProcessing.avgPowerInBins[i][j]); // [CHAN][BAND]
                    }
                    try {
                        this.osc.send(msg,this.netaddress);
                    } catch (Exception e) {
                        println(e.getMessage());
                    }
                }
            // UDP
            } else if (this.protocol.equals("UDP")) {
                // DELTA, THETA, ALPHA, BETA, GAMMA
                String outputter = "{\"type\":\"bandPower\",\"data\":[[";
                for (int i = 0;i < numChan; i++) {
                    for (int j=0;j<numBandPower;j++) {
                        outputter += str(dataProcessing.avgPowerInBins[i][j]); //[CHAN][BAND]
                        if (j != numBandPower - 1) {
                            outputter += ",";
                        }
                    }
                    if (i != numChan - 1) {
                        outputter += "],[";
                    } else {
                        outputter += "]]}\r\n";
                    }
                }
                try {
                    this.udp.send(outputter, this.ip, this.port);
                } catch (Exception e) {
                    println(e.getMessage());
                }
                // LSL
            } else if (this.protocol.equals("LSL")) {

                float[] avgPowerLSL = new float[numChan*numBandPower];
                for (int i=0; i<numChan;i++) {
                    for (int j=0;j<numBandPower;j++) {
                        dataToSend[j+numBandPower*i] = dataProcessing.avgPowerInBins[i][j];
                    }
                }
                // Add timestamp to LSL Stream
                outlet_data.push_chunk(dataToSend, System.currentTimeMillis());
            } else if (this.protocol.equals("Serial")) {
                for (int i=0;i<numChan;i++) {
                    serialMessage = "[" + (i+1) + ","; //clear message
                    for (int j=0;j<numBandPower;j++) {
                        float power_band = dataProcessing.avgPowerInBins[i][j];
                        String power_band_3dec = String.format("%.3f", power_band);
                        serialMessage += power_band_3dec;
                        if (j < numBandPower-1) {
                            serialMessage += ",";  //add a comma to serialMessage to separate chan values, as long as it isn't last value...
                        }
                    }
                    serialMessage += "]";
                    try {
                        // println(serialMessage);
                        this.serial_networking.write(serialMessage);
                    } catch (Exception e) {
                        println(e.getMessage());
                    }
                }
            }
        }
    }

    void sendEMGData() {
        // UNFILTERED & FILTERED ... influenced globally by the FFT filters dropdown ... just like the FFT data
        if (this.filter==0 || this.filter==1) {
            // OSC
            if (this.protocol.equals("OSC")) {
                for (int i=0;i<numChan;i++) {
                    msg.clearArguments();
                    msg.add(i+1);
                    //ADD NORMALIZED EMG CHANNEL DATA
                    msg.add(w_emg.motorWidgets[i].output_normalized);
                    // println(i + " | " + w_emg.motorWidgets[i].output_normalized);
                    try {
                        this.osc.send(msg,this.netaddress);
                    } catch (Exception e) {
                        println(e.getMessage());
                    }
                }
            // UDP
            } else if (this.protocol.equals("UDP")) {
                String outputter = "{\"type\":\"emg\",\"data\":[";
                for (int i = 0;i < numChan; i++) {
                    outputter += str(w_emg.motorWidgets[i].output_normalized);
                    if (i != numChan - 1) {
                        outputter += ",";
                    } else {
                        outputter += "]}\r\n";
                    }
                }
                try {
                    this.udp.send(outputter, this.ip, this.port);
                } catch (Exception e) {
                    println(e.getMessage());
                }
                // LSL
            } else if (this.protocol.equals("LSL")) {
                if (filter==0) {
                    for (int j=0;j<numChan;j++) {
                        dataToSend[j] = w_emg.motorWidgets[j].output_normalized;
                    }
                    // Add timestamp to LSL Stream
                    outlet_data.push_sample(dataToSend, System.currentTimeMillis());
                }
            } else if (this.protocol.equals("Serial")) {     // Send NORMALIZED EMG CHANNEL Data over Serial ... %%%%%
                serialMessage = "";
                for (int i=0;i<numChan;i++) {
                    float emg_normalized = w_emg.motorWidgets[i].output_normalized;
                    String emg_normalized_3dec = String.format("%.3f", emg_normalized);
                    serialMessage += emg_normalized_3dec;
                    if (i != numChan - 1) {
                        serialMessage += ",";
                    } else {
                        serialMessage += "\n";
                    }
                }
                try {
                    println(serialMessage);
                    this.serial_networking.write(serialMessage);
                } catch (Exception e) {
                    println(e.getMessage());
                }
            }
        }
    }


    void sendAccelerometerData() {
        // UNFILTERED & FILTERED, Accel data is not affected by filters anyways
        if (this.filter==0 || this.filter==1) {
            // OSC
            if (this.protocol.equals("OSC")) {
                for (int i = 0; i < NUM_ACCEL_DIMS; i++) {
                    msg.clearArguments();
                    msg.add(i+1);
                    //ADD Accelerometer data
                    msg.add(w_accelerometer.getCurrentAccelVal(i));
                    // println(i + " | " + w_accelerometer.getCurrentAccelVal(i));
                    try {
                        this.osc.send(msg,this.netaddress);
                    } catch (Exception e) {
                        println(e.getMessage());
                    }
                }
            // UDP
            } else if (this.protocol.equals("UDP")) {
                String outputter = "{\"type\":\"accelerometer\",\"data\":[";
                for (int i = 0; i < NUM_ACCEL_DIMS; i++) {
                    float accelData = w_accelerometer.getCurrentAccelVal(i);
                    String accelData_3dec = String.format("%.3f", accelData);
                    outputter += accelData_3dec;
                    if (i != NUM_ACCEL_DIMS - 1) {
                        outputter += ",";
                    } else {
                        outputter += "]}\r\n";
                    }
                }
                try {
                    this.udp.send(outputter, this.ip, this.port);
                } catch (Exception e) {
                    println(e.getMessage());
                }
                // LSL
            } else if (this.protocol.equals("LSL")) {
                for (int i = 0; i < NUM_ACCEL_DIMS; i++) {
                    dataToSend[i] = w_accelerometer.getCurrentAccelVal(i);
                }
                // Add timestamp to LSL Stream
                outlet_data.push_sample(dataToSend, System.currentTimeMillis());
            } else if (this.protocol.equals("Serial")) {
                // Data Format: +0.900,-0.042,+0.254\n
                // 7 chars per axis, including \n char for Z
                serialMessage = "";
                for (int i = 0; i < NUM_ACCEL_DIMS; i++) {
                    float accelData = w_accelerometer.getCurrentAccelVal(i);
                    String accelData_3dec = String.format("%.3f", accelData);
                    if (accelData >= 0) serialMessage += "+";
                    serialMessage += accelData_3dec;
                    if (i != NUM_ACCEL_DIMS - 1) {
                        serialMessage += ",";
                    } else {
                        serialMessage += "\n";
                    }
                }
                try {
                    //println(serialMessage);
                    this.serial_networking.write(serialMessage);
                } catch (Exception e) {
                    println(e.getMessage());
                }
            }
        }
    }

    void sendAnalogReadData() {
        final int NUM_ANALOG_READS = w_analogRead.getNumAnalogReads();
        // UNFILTERED & FILTERED, Aux data is not affected by filters anyways
        if (this.filter==0 || this.filter==1) {
            // OSC
            if (this.protocol.equals("OSC")) {
                for (int i = 0; i < NUM_ANALOG_READS; i++) {
                    msg.clearArguments();
                    msg.add(i+1);
                    //ADD Accelerometer data
                    msg.add(hub.validAccelValues[i]);
                    // println(i + " | " + hub.validAccelValues[i]);
                    try {
                        this.osc.send(msg,this.netaddress);
                    } catch (Exception e) {
                        println(e.getMessage());
                    }
                }
            // UDP
            } else if (this.protocol.equals("UDP")) {
                String outputter = "{\"type\":\"auxiliary\",\"data\":[";
                for (int i = 0; i < NUM_ANALOG_READS; i++) {
                    int auxData = hub.validAccelValues[i];
                    String auxData_formatted = String.format("%04d", auxData);
                    outputter += auxData_formatted;
                    if (i != NUM_ANALOG_READS - 1) {
                        outputter += ",";
                    } else {
                        outputter += "]}\r\n";
                    }
                }
                try {
                    this.udp.send(outputter, this.ip, this.port);
                } catch (Exception e) {
                    println(e.getMessage());
                }
                // LSL
            } else if (this.protocol.equals("LSL")) {
                for (int i = 0; i < NUM_ANALOG_READS; i++) {
                    dataToSend[i] = hub.validAccelValues[i];
                }
                // Add timestamp to LSL Stream
                outlet_data.push_sample(dataToSend, System.currentTimeMillis());
            } else if (this.protocol.equals("Serial")) {
                // Data Format: 0001,0002,0003\n or 0001,0002\n depending if Wifi Shield is used
                // 5 chars per pin, including \n char for Z
                serialMessage = "";
                for (int i = 0; i < NUM_ANALOG_READS; i++) {
                    int auxData = hub.validAccelValues[i];
                    String auxData_formatted = String.format("%04d", auxData);
                    serialMessage += auxData_formatted;
                    if (i != NUM_ANALOG_READS - 1) {
                        serialMessage += ",";
                    } else {
                        serialMessage += "\n";
                    }
                }
                try {
                    //println(serialMessage);
                    this.serial_networking.write(serialMessage);
                } catch (Exception e) {
                    println(e.getMessage());
                }
            }
        }
    }

    void sendDigitalReadData() {
        final int NUM_DIGITAL_READS = w_digitalRead.getNumDigitalReads();
        // UNFILTERED & FILTERED, Aux data is not affected by filters anyways
        if (this.filter==0 || this.filter==1) {
            // OSC
            if (this.protocol.equals("OSC")) {
                for (int i = 0; i < NUM_DIGITAL_READS; i++) {
                    msg.clearArguments();
                    msg.add(i+1);
                    //ADD Accelerometer data
                    msg.add(w_digitalRead.digitalReadDots[i].getDigitalReadVal());
                    // println(i + " | " + hub.validAccelValues[i]);
                    try {
                        this.osc.send(msg,this.netaddress);
                    } catch (Exception e) {
                        println(e.getMessage());
                    }
                }
            // UDP
            } else if (this.protocol.equals("UDP")) {
                String outputter = "{\"type\":\"auxiliary\",\"data\":[";
                for (int i = 0; i < NUM_DIGITAL_READS; i++) {
                    int auxData = w_digitalRead.digitalReadDots[i].getDigitalReadVal();
                    String auxData_formatted = String.format("%d", auxData);
                    outputter += auxData_formatted;
                    if (i != NUM_DIGITAL_READS - 1) {
                        outputter += ",";
                    } else {
                        outputter += "]}\r\n";
                    }
                }
                try {
                    this.udp.send(outputter, this.ip, this.port);
                } catch (Exception e) {
                    println(e.getMessage());
                }
                // LSL
            } else if (this.protocol.equals("LSL")) {
                for (int i = 0; i < NUM_DIGITAL_READS; i++) {
                    dataToSend[i] = w_digitalRead.digitalReadDots[i].getDigitalReadVal();
                }
                // Add timestamp to LSL Stream
                outlet_data.push_sample(dataToSend, System.currentTimeMillis());
            } else if (this.protocol.equals("Serial")) {
                // Data Format: 0,1,0,1,0\n or 0,1,0\n depending if WiFi Shield is used
                // 2 chars per pin, including \n char last pin
                serialMessage = "";
                for (int i = 0; i < NUM_DIGITAL_READS; i++) {
                    int auxData = w_digitalRead.digitalReadDots[i].getDigitalReadVal();
                    String auxData_formatted = String.format("%d", auxData);
                    serialMessage += auxData_formatted;
                    if (i != NUM_DIGITAL_READS - 1) {
                        serialMessage += ",";
                    } else {
                        serialMessage += "\n";
                    }
                }
                try {
                    //println(serialMessage);
                    this.serial_networking.write(serialMessage);
                } catch (Exception e) {
                    println(e.getMessage());
                }
            }
        }
    }

    void sendFocusData() {
        // UNFILTERED & FILTERED ... influenced globally by the FFT filters dropdown ... just like the FFT data
        if (this.filter==0 || this.filter==1) {
            // OSC
            if (this.protocol.equals("OSC")) {
                msg.clearArguments();
                //ADD Focus Data
                msg.add(w_focus.isFocused);
                try {
                    this.osc.send(msg,this.netaddress);
                } catch (Exception e) {
                    println(e.getMessage());
                }
            // UDP
            } else if (this.protocol.equals("UDP")) {
                String outputter = "{\"type\":\"focus\",\"data\":";
                outputter += str(w_focus.isFocused ? 1.0 : 0.0);
                outputter += "]}\r\n";
                try {
                    this.udp.send(outputter, this.ip, this.port);
                } catch (Exception e) {
                    println(e.getMessage());
                }
            // LSL
            } else if (this.protocol.equals("LSL")) {
                // convert boolean to float and only sends the first data
                float temp = w_focus.isFocused ? 1.0 : 0.0;
                dataToSend[0] = temp;
                // Add timestamp to LSL Stream
                outlet_data.push_sample(dataToSend, System.currentTimeMillis());
            // Serial
            } else if (this.protocol.equals("Serial")) {     // Send NORMALIZED EMG CHANNEL Data over Serial ... %%%%%
                serialMessage = ""; //clear message
                String isFocused = Boolean.toString(w_focus.isFocused);
                serialMessage += isFocused;
                serialMessage += "\n";
                try {
                    //println("SerialMessage: " + serialMessage);
                    this.serial_networking.write(serialMessage);
                } catch (Exception e) {
                    println("SerialMessage: Focus Error");
                    println(e.getMessage());
                }
            }
        }
    }
    //////////////////////////////////////Stream SSVEP data from W_SSVEP
    void sendSSVEPData() {
        // UNFILTERED & FILTERED ... influenced globally by the FFT filters dropdown ... just like the FFT data
        if (this.filter==0 || this.filter==1){
            // OSC
            if (this.protocol.equals("OSC")){
                for (int i=0;i<w_ssvep.ssvepData.length;i++) {
                    msg.clearArguments();
                    msg.add(i+1);
                    //ADD NORMALIZED EMG CHANNEL DATA
                    msg.add(w_ssvep.ssvepData[i]);
                    // println(i + " | " + w_emg.motorWidgets[i].output_normalized);
                    try {
                        this.osc.send(msg,this.netaddress);
                    } catch (Exception e) {
                        println(e.getMessage());
                    }
                }
            // UDP
            } else if (this.protocol.equals("UDP")){
                String outputter = "{\"type\":\"SSVEP\",\"data\":";
                for (int i = 0; i < w_ssvep.ssvepData.length; i++) {
                    outputter += str(w_ssvep.ssvepData[i]);
                    outputter += ",";
                }
                outputter += "]}\r\n";
                try {
                    this.udp.send(outputter, this.ip, this.port);
                } catch (Exception e) {
                    println(e.getMessage());
                }
            // LSL
            } else if (this.protocol.equals("LSL")){
                for (int i = 0; i < w_ssvep.ssvepData.length; i++) {
                    dataToSend[i] = w_ssvep.ssvepData[i];
                }
                // Add timestamp to LSL Stream
                outlet_data.push_sample(dataToSend, System.currentTimeMillis());
            // Serial
            } else if (this.protocol.equals("Serial")){     // Send SSVEP Data over Serial ...
                serialMessage = ""; //clear message
                for (int i = 0; i < w_ssvep.ssvepData.length; i++) {
                    serialMessage += String.format("%.3f", w_ssvep.ssvepData[i]);
                    if (i != w_ssvep.ssvepData.length - 1) {
                        serialMessage += ",";
                    } else {
                        serialMessage += "\n";
                    }
                }
                try {
                    //println("SerialMessage: SSVEP = " + serialMessage);
                    this.serial_networking.write(serialMessage);
                } catch (Exception e){
                    println("SerialMessage: Focus Error");
                    println(e.getMessage());
                }
            }
        }
    }
    ////////////////////////////////////// Stream pulse data from W_PulseSensor
    void sendPulseData() {
        if (this.filter==0 || this.filter==1) {
            // OSC
            if (this.protocol.equals("OSC")) {
                //ADD BPM Data (BPM, Signal, IBI)
                for (int i = 0; i < (w_pulsesensor.PulseWaveY.length); i++) {//This works
                    msg.clearArguments(); //This belongs here
                    msg.add(w_pulsesensor.BPM); //Add BPM first
                    msg.add(w_pulsesensor.PulseWaveY[i]); //Add Raw Signal second
                    msg.add(w_pulsesensor.IBI); //Add IBI third
                    //Message received in Max via OSC is a list of three integers without commas: 75 512 600 : BPM Signal IBI
                    //println(" " + this.port + " ~~~~ " + w_pulsesensor.BPM + "," +  w_pulsesensor.PulseWaveY[i] + "," + w_pulsesensor.IBI);
                    try {
                        this.osc.send(msg,this.netaddress);
                    } catch (Exception e) {
                        println(e.getMessage());
                    }
                }
            // UDP
            } else if (this.protocol.equals("UDP")) { //////////////////This needs to be checked
                String outputter = "{\"type\":\"pulse\",\"data\":";
                for (int i = 0; i < (w_pulsesensor.PulseWaveY.length); i++) {
                    outputter += str(w_pulsesensor.BPM) + ",";  //Comma separated string output (BPM,Raw Signal,IBI)
                    outputter += str(w_pulsesensor.PulseWaveY[i]) + ",";
                    outputter += str(w_pulsesensor.IBI);
                    outputter += "]}\r\n";
                    try {
                        this.udp.send(outputter, this.ip, this.port);
                    } catch (Exception e) {
                        println(e.getMessage());
                    }
                }
            // LSL
            } else if (this.protocol.equals("LSL")) { ///////////////////This needs to be checked
                for (int i = 0; i < (w_pulsesensor.PulseWaveY.length); i++) {
                    dataToSend[0] = w_pulsesensor.BPM;  //Array output
                    dataToSend[1] = w_pulsesensor.PulseWaveY[i];
                    dataToSend[2] = w_pulsesensor.IBI;
                }
                // Add timestamp to LSL Stream
                outlet_data.push_chunk(dataToSend, System.currentTimeMillis());
            // Serial
            } else if (this.protocol.equals("Serial")) {     // Send Pulse Data (BPM,Signal,IBI) over Serial
                for (int i = 0; i < (w_pulsesensor.PulseWaveY.length); i++) {
                    serialMessage = ""; //clear message
                    int BPM = (w_pulsesensor.BPM);
                    int Signal = (w_pulsesensor.PulseWaveY[i]);
                    int IBI = (w_pulsesensor.IBI);
                    serialMessage += BPM + ","; //Comma separated string output (BPM,Raw Signal,IBI)
                    serialMessage += Signal + ",";
                    serialMessage += IBI;
                    try {
                        println(serialMessage);
                        this.serial_networking.write(serialMessage);
                    } catch (Exception e) {
                        println(e.getMessage());
                    }
                }
            }
        }
    }//End sendPulseData

    //// Add new stream function here (ex. sendWidgetData) in the same format as above

    void quit() {
        this.isStreaming=false;
        closeNetwork();
        interrupt();
    }

    void closeNetwork() {
        if (this.protocol.equals("OSC")) {
            try {
                this.osc.stop();
            } catch (Exception e) {
                println(e.getMessage());
            }
        } else if (this.protocol.equals("UDP")) {
            this.udp.close();
        } else if (this.protocol.equals("LSL")) {
            outlet_data.close();
        } else if (this.protocol.equals("Serial")) {
            //Close Serial Port %%%%%
            try {
                serial_networking.clear();
                serial_networking.stop();
                println("Successfully closed SERIAL/COM port " + this.portName);
            } catch (Exception e) {
                println("Failed to close SERIAL/COM port " + this.portName);
            }
        }
    }

    void openNetwork() {
        println("Networking: " + getAttributes());
        if (this.protocol.equals("OSC")) {
            //Possibly enter a nice custom exception here
            //try {
                this.osc = new OscP5(this,this.port + 1000);
                this.netaddress = new NetAddress(this.ip,this.port);
                this.msg = new OscMessage(this.address);
            //} catch (Exception e) {
            //}
        } else if (this.protocol.equals("UDP")) {
            this.udp = new UDP(this);
            this.udp.setBuffer(20000);
            this.udp.listen(false);
            this.udp.log(false);
            output("UDP successfully connected");
        } else if (this.protocol.equals("LSL")) {
            String stream_id = "openbcieeg12345";
            info_data = new LSL.StreamInfo(
                        this.streamName,
                        this.streamType,
                        this.nChanLSL,
                        getSampleRateSafe(),
                        LSL.ChannelFormat.float32,
                        stream_id
                    );
            outlet_data = new LSL.StreamOutlet(info_data);
        } else if (this.protocol.equals("Serial")) {
            //Open Serial Port! %%%%%
            try {
                serial_networking = new Serial(this.pApplet, this.portName, this.baudRate);
                serial_networking.clear();
                verbosePrint("Successfully opened SERIAL/COM: " + this.portName);
                output("Successfully opened SERIAL/COM (" + this.baudRate + "): " + this.portName );
            } catch (Exception e) {
                verbosePrint("W_Networking.pde: could not open SERIAL PORT: " + this.portName);
                println("Error: " + e);
            }
        }
    }

    //used only to print attributes to the screen
    StringList getAttributes() {
        StringList attributes = new StringList();
        if (this.protocol.equals("OSC")) {
            attributes.append(this.dataType);
            attributes.append(this.ip);
            attributes.append(str(this.port));
            attributes.append(this.address);
            attributes.append(str(this.filter));
        } else if (this.protocol.equals("UDP")) {
            attributes.append(this.dataType);
            attributes.append(this.ip);
            attributes.append(str(this.port));
            attributes.append(str(this.filter));
        } else if (this.protocol.equals("LSL")) {
            attributes.append(this.dataType);
            attributes.append(this.streamName);
            attributes.append(this.streamType);
            attributes.append(str(this.nChanLSL));
            attributes.append(str(this.filter));
        } else if (this.protocol.equals("Serial")) {
            // Add Serial Port Attributes %%%%%
        }
        return attributes;
    }
}

/* Dropdown Menu Callback Functions */
/**
  * @description Sets the selected protocol mode from the widget's dropdown menu
  * @param `n` {int} - Index of protocol item selected in menu
  */
void Protocol(int protocolIndex) {
    settings.nwProtocolSave = protocolIndex;
    if (protocolIndex==3) {
        w_networking.protocolMode = "OSC";
    } else if (protocolIndex==2) {
        w_networking.protocolMode = "UDP";
    } else if (protocolIndex==1) {
        w_networking.protocolMode = "LSL";
    } else if (protocolIndex==0) {
        w_networking.protocolMode = "Serial";
        w_networking.disableCertainOutputs((int)w_networking.cp5_networking_dropdowns.get(ScrollableList.class, "dataType1").getValue());
    }
    println("Networking: Protocol mode set to " + w_networking.protocolMode);
    w_networking.screenResized();
    w_networking.showCP5();
    closeAllDropdowns();
}

void dataType1(int n) {
    w_networking.closeAllDropdowns();
}
void dataType2(int n) {
    w_networking.closeAllDropdowns();
}
void dataType3(int n) {
    w_networking.closeAllDropdowns();
}
void dataType4(int n) {
    w_networking.closeAllDropdowns();
}
void port_name(int n) {
    w_networking.setComPortToSave(n);
    w_networking.closeAllDropdowns();
}
void baud_rate(int n) {
    w_networking.closeAllDropdowns();
}
void filter1(int n) {
    w_networking.closeAllDropdowns();
}
void filter2(int n) {
    w_networking.closeAllDropdowns();
}
void filter3(int n) {
    w_networking.closeAllDropdowns();
}
void filter4(int n) {
    w_networking.closeAllDropdowns();
}
