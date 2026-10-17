import SwiftUI
import PhotosUI

struct ScannerView: View {
    @EnvironmentObject var scannerVM: ScannerViewModel
    @EnvironmentObject var menuVM: MenuViewModel
    @State private var photoItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if let img = scannerVM.selectedImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 220)
                        .cornerRadius(12)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.appSecondary)
                        .frame(height: 220)
                        .overlay(
                            VStack {
                                Image(systemName: "camera.viewfinder").font(.system(size: 48)).foregroundColor(.secondary)
                                Text("Сфотографируйте меню").foregroundColor(.secondary)
                            }
                        )
                }

                PhotosPicker(selection: $photoItem, matching: .images) {
                    Label("Выбрать фото", systemImage: "photo")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.appPrimary)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .onChange(of: photoItem) { newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let img = UIImage(data: data) {
                            scannerVM.process(image: img)
                        }
                    }
                }

                if scannerVM.isProcessing {
                    ProgressView("Распознавание...")
                }

                if let err = scannerVM.errorMessage {
                    Text(err).foregroundColor(.red).font(.caption)
                }

                if !scannerVM.recognized.isEmpty {
                    List {
                        ForEach(scannerVM.recognized) { item in
                            RecognizedRow(item: item)
                        }
                    }
                    .listStyle(.plain)
                    .frame(maxHeight: 300)

                    PrimaryButton("Импортировать выбранные (\(scannerVM.recognized.filter { $0.isSelected }.count))", icon: "square.and.arrow.down") {
                        scannerVM.importSelected()
                        menuVM.load()
                    }
                }
            }
            .padding()
            .navigationTitle("Сканер меню")
        }
    }
}

struct RecognizedRow: View {
    @EnvironmentObject var scannerVM: ScannerViewModel
    let item: RecognizedMenuItem

    var body: some View {
        HStack {
            Button { scannerVM.toggleSelection(item) } label: {
                Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isSelected ? .appPrimary : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                TextField("Название", text: Binding(
                    get: { item.name },
                    set: { scannerVM.updateName(item, name: $0) }
                ))
                .font(.subheadline.bold())
                HStack {
                    TextField("Цена", value: Binding(
                        get: { item.price },
                        set: { scannerVM.updatePrice(item, price: $0) }
                    ), format: .number)
                    .keyboardType(.decimalPad)
                    .frame(width: 80)
                    Picker("", selection: Binding(
                        get: { item.category },
                        set: { scannerVM.updateCategory(item, category: $0) }
                    )) {
                        ForEach(MenuCategory.allCases) { c in Text(c.rawValue).tag(c) }
                    }
                    .pickerStyle(.menu)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
