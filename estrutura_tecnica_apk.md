# Estrutura Técnica e Esboço de Telas

## Estrutura de Projeto Android

```
app/
├── src/main/
│   ├── java/com/seu_app/
│   │   ├── ui/
│   │   │   ├── screens/
│   │   │   │   ├── ConfigScreen.kt          (Tela 1)
│   │   │   │   ├── ScannerScreen.kt         (Tela 2)
│   │   │   │   ├── ContinuityDialog.kt      (Tela 3)
│   │   │   │   └── ValidationScreen.kt      (Tela 4)
│   │   │   ├── components/
│   │   │   │   ├── CameraPreview.kt
│   │   │   │   ├── EquipmentList.kt
│   │   │   │   └── ExportButtons.kt
│   │   │   └── theme/
│   │   │       └── Theme.kt
│   │   │
│   │   ├── data/
│   │   │   ├── database/
│   │   │   │   ├── AppDatabase.kt
│   │   │   │   └── EquipmentDao.kt
│   │   │   ├── models/
│   │   │   │   └── Equipment.kt
│   │   │   └── repository/
│   │   │       └── EquipmentRepository.kt
│   │   │
│   │   ├── viewmodel/
│   │   │   └── CollectionViewModel.kt
│   │   │
│   │   ├── utils/
│   │   │   ├── ExportUtils.kt
│   │   │   ├── BarcodeScanner.kt
│   │   │   └── Constants.kt
│   │   │
│   │   └── MainActivity.kt
│   │
│   └── res/
│       └── ...
│
└── build.gradle
```

---

## Modelo de Dados (Equipment.kt)

```kotlin
@Entity(tableName = "equipments")
data class Equipment(
    @PrimaryKey(autoGenerate = true)
    val id: Int = 0,
    val localidade: String,
    val tipo: String, // "CPU" ou "Monitor"
    val codigoLido: String,
    val timestamp: Long = System.currentTimeMillis(),
    val sincronizado: Boolean = false
)
```

---

## ViewModel Principal

```kotlin
class CollectionViewModel(
    private val repository: EquipmentRepository
) : ViewModel() {
    
    // Estado atual
    private val _localidade = MutableLiveData<String>("")
    private val _tipoEquipamento = MutableLiveData<String>("CPU")
    private val _equipamentosColetados = MutableLiveData<List<Equipment>>(emptyList())
    private val _contadorAtual = MutableLiveData<Int>(0)
    
    val localidade: LiveData<String> = _localidade
    val tipoEquipamento: LiveData<String> = _tipoEquipamento
    val equipamentosColetados: LiveData<List<Equipment>> = _equipamentosColetados
    val contadorAtual: LiveData<Int> = _contadorAtual
    
    // Métodos
    fun setLocalidade(localidade: String) {
        _localidade.value = localidade
    }
    
    fun setTipoEquipamento(tipo: String) {
        _tipoEquipamento.value = tipo
        _contadorAtual.value = 0 // Reseta contador
    }
    
    fun adicionarEquipamento(codigo: String) {
        viewModelScope.launch {
            // Verificar duplicata
            val existe = _equipamentosColetados.value?.any { 
                it.codigoLido == codigo && it.tipo == _tipoEquipamento.value 
            } ?: false
            
            if (!existe) {
                val equipment = Equipment(
                    localidade = _localidade.value ?: "",
                    tipo = _tipoEquipamento.value ?: "CPU",
                    codigoLido = codigo
                )
                repository.inserirEquipamento(equipment)
                _contadorAtual.value = (_contadorAtual.value ?: 0) + 1
                carregarEquipamentos()
            }
        }
    }
    
    fun carregarEquipamentos() {
        viewModelScope.launch {
            val equipamentos = repository.obterEquipamentosDALocalidade(_localidade.value ?: "")
            _equipamentosColetados.value = equipamentos
        }
    }
    
    fun deletarEquipamento(id: Int) {
        viewModelScope.launch {
            repository.deletarEquipamento(id)
            carregarEquipamentos()
        }
    }
    
    fun limparTudo() {
        _equipamentosColetados.value = emptyList()
        _contadorAtual.value = 0
        _localidade.value = ""
    }
}
```

---

## Exportação em TXT

```kotlin
fun exportarTXT(equipamentos: List<Equipment>, localidade: String): File {
    val fileName = "coleta_${localidade}_${System.currentTimeMillis()}.txt"
    val file = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS), fileName)
    
    val cpus = equipamentos.filter { it.tipo == "CPU" }
    val monitores = equipamentos.filter { it.tipo == "Monitor" }
    
    val conteudo = """
        RELATÓRIO DE COLETA DE EQUIPAMENTOS
        =====================================
        Localidade: $localidade
        Data: ${SimpleDateFormat("dd/MM/yyyy HH:mm", Locale.getDefault()).format(Date())}
        
        CPUS (${cpus.size} equipamentos):
        ${cpus.mapIndexed { index, eq -> 
            "- ${eq.codigoLido} (${SimpleDateFormat("HH:mm", Locale.getDefault()).format(eq.timestamp)})"
        }.joinToString("\n")}
        
        MONITORES (${monitores.size} equipamentos):
        ${monitores.mapIndexed { index, eq -> 
            "- ${eq.codigoLido} (${SimpleDateFormat("HH:mm", Locale.getDefault()).format(eq.timestamp)})"
        }.joinToString("\n")}
        
        TOTAL: ${equipamentos.size} equipamentos
    """.trimIndent()
    
    file.writeText(conteudo)
    return file
}
```

---

## Exportação em XLSX

```kotlin
fun exportarXLSX(equipamentos: List<Equipment>, localidade: String): File {
    val workbook = XSSFWorkbook()
    
    // Aba 1: Resumo
    val sheetResumo = workbook.createSheet("Resumo")
    val rowResumo = sheetResumo.createRow(0)
    rowResumo.createCell(0).setCellValue("Localidade: $localidade")
    sheetResumo.createRow(2).createCell(0).setCellValue("CPUs: ${equipamentos.count { it.tipo == "CPU" }}")
    sheetResumo.createRow(3).createCell(0).setCellValue("Monitores: ${equipamentos.count { it.tipo == "Monitor" }}")
    
    // Aba 2: CPUs
    val sheetCPU = workbook.createSheet("CPUs")
    val headerCPU = sheetCPU.createRow(0)
    headerCPU.createCell(0).setCellValue("ID")
    headerCPU.createCell(1).setCellValue("Código")
    headerCPU.createCell(2).setCellValue("Timestamp")
    
    equipamentos.filter { it.tipo == "CPU" }.forEachIndexed { index, eq ->
        val row = sheetCPU.createRow(index + 1)
        row.createCell(0).setCellValue(eq.id.toDouble())
        row.createCell(1).setCellValue(eq.codigoLido)
        row.createCell(2).setCellValue(SimpleDateFormat("dd/MM/yyyy HH:mm", Locale.getDefault()).format(eq.timestamp))
    }
    
    // Aba 3: Monitores
    val sheetMonitor = workbook.createSheet("Monitores")
    val headerMonitor = sheetMonitor.createRow(0)
    headerMonitor.createCell(0).setCellValue("ID")
    headerMonitor.createCell(1).setCellValue("Código")
    headerMonitor.createCell(2).setCellValue("Timestamp")
    
    equipamentos.filter { it.tipo == "Monitor" }.forEachIndexed { index, eq ->
        val row = sheetMonitor.createRow(index + 1)
        row.createCell(0).setCellValue(eq.id.toDouble())
        row.createCell(1).setCellValue(eq.codigoLido)
        row.createCell(2).setCellValue(SimpleDateFormat("dd/MM/yyyy HH:mm", Locale.getDefault()).format(eq.timestamp))
    }
    
    val fileName = "coleta_${localidade}_${System.currentTimeMillis()}.xlsx"
    val file = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS), fileName)
    FileOutputStream(file).use { workbook.write(it) }
    workbook.close()
    
    return file
}
```

---

## Dependencies (build.gradle)

```gradle
dependencies {
    // Kotlin
    implementation 'androidx.core:core-ktx:1.10.1'
    implementation 'org.jetbrains.kotlin:kotlin-stdlib'
    
    // Jetpack Compose (recomendado para UI ágil)
    implementation 'androidx.compose.ui:ui:1.5.3'
    implementation 'androidx.compose.material3:material3:1.1.1'
    implementation 'androidx.activity:activity-compose:1.7.2'
    
    // LiveData e ViewModel
    implementation 'androidx.lifecycle:lifecycle-viewmodel-ktx:2.6.1'
    implementation 'androidx.lifecycle:lifecycle-livedata-ktx:2.6.1'
    
    // Room Database
    implementation 'androidx.room:room-runtime:2.5.2'
    implementation 'androidx.room:room-ktx:2.5.2'
    kapt 'androidx.room:room-compiler:2.5.2'
    
    // ML Kit Barcode Scanning
    implementation 'com.google.mlkit:barcode-scanning:17.0.3'
    
    // CameraX
    implementation 'androidx.camera:camera-core:1.2.3'
    implementation 'androidx.camera:camera-camera2:1.2.3'
    implementation 'androidx.camera:camera-lifecycle:1.2.3'
    
    // Apache POI (para XLSX)
    implementation 'org.apache.poi:poi-ooxml:5.2.3'
    
    // Permissions
    implementation 'com.google.accompanist:accompanist-permissions:0.32.0'
}
```

---

## Androidmanifest.xml - Permissões

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.ACCESS_MEDIA_LOCATION" />
    
    <application>
        <!-- ... -->
    </application>
    
</manifest>
```

---

## Fluxo de Implementação Recomendado

1. **Fase 1:** Tela 1 (Config) + Banco de dados
2. **Fase 2:** Tela 2 (Scanner com ML Kit)
3. **Fase 3:** Tela 3 (Dialog) + Lógica de continuidade
4. **Fase 4:** Tela 4 (Validação) + Exportação TXT/XLSX
5. **Testes:** Em dispositivos físicos

