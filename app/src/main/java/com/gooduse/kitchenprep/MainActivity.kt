package com.gooduse.kitchenprep

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import com.gooduse.kitchenprep.ui.KitchenPrepApp
import com.gooduse.kitchenprep.ui.KitchenPrepTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        val shared = intent.takeIf { it.action == Intent.ACTION_SEND }?.getStringExtra(Intent.EXTRA_TEXT)
        setContent {
            val vm: KitchenPrepViewModel = viewModel(factory = KitchenPrepViewModel.factory(applicationContext))
            val ui by vm.state.collectAsState()
            KitchenPrepTheme(ui.theme) { KitchenPrepApp(vm, shared) }
        }
    }
}
