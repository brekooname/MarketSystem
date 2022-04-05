import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:marketsystem/controllers/products_controller.dart';
import 'package:marketsystem/layout/market_controller.dart';
import 'package:marketsystem/layout/market_layout.dart';
import 'package:marketsystem/models/product.dart';
import 'package:marketsystem/shared/components/default_button.dart';
import 'package:marketsystem/shared/components/default_text_form.dart';
import 'package:marketsystem/shared/constant.dart';
import 'package:marketsystem/shared/toast_message.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class AddProductScreen extends StatefulWidget {
  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? qrViewcontroller;
  Barcode? barCode = null;

  var productbarcodeController_text = TextEditingController();
  var productNameController_text = TextEditingController();
  var productPriceController_text = TextEditingController();
  var productQtyController = TextEditingController();

  GlobalKey<FormState> _formkey = GlobalKey<FormState>();

  @override
  void dispose() {
    // TODO: implement dispose
    this.qrViewcontroller?.dispose();
    super.dispose();
  }

  void reassemble() async {
    super.reassemble();
    if (Platform.isAndroid) {
      await qrViewcontroller?.pauseCamera();
    }
    qrViewcontroller?.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (BuildContext context) => ProductsController(),
      child: Scaffold(
        appBar: AppBar(
          title: Text("Add New Product"),
        ),
        body: Stack(
          alignment: Alignment.topCenter,
          children: [
            _buildQr(context),
            Positioned(
              bottom: 10,
              child: _buildResult(),
            ),
            Positioned(
              top: 10,
              child: _buildControlButton(),
            ),
            if (barCode != null)
              Align(
                  alignment: Alignment.center,
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _build_Form(),
                        SizedBox(
                          height: 15,
                        ),
                        _buildSubmitRow(),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  _buildResult() => GestureDetector(
        onTap: () {
          setState(() {
            this.barCode = Barcode(''.trim(), BarcodeFormat.codabar, []);
          });
        },
        child: Container(
          decoration: BoxDecoration(color: defaultColor),
          padding: EdgeInsets.all(15),
          child: Text(
            "Continue Without Scan",
            style: TextStyle(fontSize: 24, color: Colors.white),
          ),
        ),
      );

  _buildQr(BuildContext context) => QRView(
        key: qrKey,
        onQRViewCreated: onQRViewCreatedCallback,
        overlay: QrScannerOverlayShape(
            borderColor: defaultColor,
            borderWidth: 7,
            borderLength: 20,
            borderRadius: 10,
            cutOutSize: MediaQuery.of(context).size.width * 0.7),
      );

  void onQRViewCreatedCallback(QRViewController controller) {
    setState(() {
      this.qrViewcontroller = controller;
    });

    qrViewcontroller?.scannedDataStream.listen((barcode) => setState(() {
          this.barCode = barcode;
          qrViewcontroller?.pauseCamera();
          //NOTE when scan is finished write the barcode in controller
          productbarcodeController_text.text = barcode.code.toString();
        }));
  }

  _build_Form() => SingleChildScrollView(
        child: Form(
            key: _formkey,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: [
                  TextFormField(
                    validator: (value) {
                      if (value!.isEmpty) {
                        return "barcode must not be empty";
                      }
                    },
                    controller: productbarcodeController_text,
                    //initialValue: barCode!.code,
                    enabled: barCode == '' ? false : true,
                    style: TextStyle(
                      fontWeight: FontWeight.normal,
                    ),
                    decoration: InputDecoration(hintText: "Barcode..."),
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  defaultTextFormField(
                      onvalidate: (value) {
                        if (value!.isEmpty) {
                          return "Name must not be empty";
                        }
                      },
                      inputtype: TextInputType.name,
                      border: UnderlineInputBorder(),
                      hinttext: "Name...",
                      controller: productNameController_text),
                  SizedBox(
                    height: 5,
                  ),
                  defaultTextFormField(
                      onvalidate: (value) {
                        if (value!.isEmpty) {
                          return "Price must not be empty";
                        }
                      },
                      inputtype: TextInputType.phone,
                      border: UnderlineInputBorder(),
                      hinttext: "Price...",
                      controller: productPriceController_text),
                  defaultTextFormField(
                      onvalidate: (value) {
                        if (value!.isEmpty) {
                          return "Qty must not be empty";
                        }
                      },
                      inputtype: TextInputType.phone,
                      border: UnderlineInputBorder(),
                      hinttext: "qty...",
                      controller: productQtyController),
                ],
              ),
            )),
      );

  _buildSubmitRow() =>
      Consumer<ProductsController>(builder: (context, controller, child) {
        return Wrap(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: defaultButton(
                  width: MediaQuery.of(context).size.width * 0.4,
                  text: "Save",
                  onpress: () async {
                    if (_formkey.currentState!.validate()) {
                      int? price =
                          int.tryParse(productPriceController_text.text);
                      int? qty = int.tryParse(productQtyController.text);
                      if (price != null && qty != null) {
                        print("valid");

                        controller
                            .insertProductByModel(
                                model: ProductModel(
                                    barcode: productbarcodeController_text.text,
                                    name: productNameController_text.text,
                                    price: productPriceController_text.text,
                                    qty: productQtyController.text))
                            .then((value) {
                          if (controller.statusInsertMessage ==
                              ToastStatus.Error) {
                            showToast(
                                message: controller.statusInsertBodyMessage
                                    .toString(),
                                status: controller.statusInsertMessage);
                          } else {
                            productNameController_text.clear();
                            productPriceController_text.clear();
                            // marketController_needed.onchangeIndex(0);

                            Get.back();
                            showToast(
                                message: controller.statusInsertBodyMessage
                                    .toString(),
                                status: controller.statusInsertMessage);
                          }
                        });
                      } else {
                        showToast(
                            message: "Price Or Qty Must be a number ",
                            status: ToastStatus.Error);
                      }
                    } else {
                      print("invalid");
                    }
                  }),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: defaultButton(
                  width: MediaQuery.of(context).size.width * 0.4,
                  text: "Rescan",
                  onpress: () {
                    productNameController_text.clear();
                    productPriceController_text.clear();
                    qrViewcontroller!.resumeCamera();
                    setState(() {
                      barCode = null;
                    });
                  }),
            ),
          ],
        );
      });

  _buildControlButton() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
              onPressed: () {
                qrViewcontroller!.toggleFlash();
              },
              icon: Icon(
                Icons.flash_on,
                color: defaultColor,
              ))
        ],
      );
}
